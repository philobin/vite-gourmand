/**
 * Realtime WebSocket Client for the `realtime-agnostic` Rust engine.
 *
 * Protocol (JSON over WebSocket):
 *
 *   → { type: "AUTH",        token: "<jwt>" }
 *   ← { type: "AUTH_OK",     conn_id: "...", server_time: "..." }
 *
 *   → { type: "SUBSCRIBE",   sub_id: "<uuid>", topic: "pg/orders/*" }
 *   ← { type: "SUBSCRIBED",  sub_id: "<uuid>", seq: 0 }
 *
 *   → { type: "UNSUBSCRIBE", sub_id: "<uuid>" }
 *   ← { type: "UNSUBSCRIBED", sub_id: "<uuid>" }
 *
 *   ← { type: "EVENT", sub_id: "<uuid>", event: { event_id, topic, event_type, sequence, timestamp, payload } }
 *
 *   → { type: "PING" }
 *   ← { type: "PONG", server_time: "..." }
 *
 * Topics follow the pattern: {prefix}/{table}/{event_type}
 *   - prefix:     "pg" for PostgreSQL, "mongo" for MongoDB
 *   - table:      table or collection name
 *   - event_type: "inserted" | "updated" | "deleted"
 *
 * Glob subscriptions:
 *   "pg/**"               → all PostgreSQL CDC events
 *   "pg/orders/*"         → all events on the orders table
 *   "pg/orders/inserted"  → only INSERTs on orders
 *
 * The payload inside EVENT.event.payload is the raw pg_notify JSON:
 *   { table, schema, operation, data, old_data }
 */

/** WebSocket origin of the realtime-agnostic engine; empty = realtime disabled. */
export const REALTIME_URL: string = import.meta.env.VITE_REALTIME_URL ?? '';
const SUPABASE_URL = REALTIME_URL;
const SUPABASE_ANON_KEY: string = import.meta.env.VITE_REALTIME_ANON_KEY ?? 'public-anon-key';

// ── Types ──────────────────────────────────────────────────────────

export type RealtimeAdapter = 'postgresql' | 'mongodb';

export type RealtimeEventType = 'INSERT' | 'UPDATE' | 'DELETE' | '*';

/**
 * Normalised CDC event — the client transforms the engine's EventPayload
 * into this shape so consumers don't need to know about the wire format.
 */
export interface RealtimeEvent<T = Record<string, unknown>> {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  schema: string;
  table: string;
  record: T;
  old_record: T | null;
  timestamp: number;
}

export interface RealtimeSubscription {
  channel: string;
  subId: string;
  unsubscribe: () => void;
}

export type ConnectionState = 'connecting' | 'connected' | 'disconnected' | 'reconnecting';

type StateCallback = (state: ConnectionState) => void;

// ── Wire protocol types (Rust engine format) ───────────────────────

interface WireClientAuth {
  type: 'AUTH';
  token: string;
}
interface WireClientSubscribe {
  type: 'SUBSCRIBE';
  sub_id: string;
  topic: string;
}
interface WireClientUnsubscribe {
  type: 'UNSUBSCRIBE';
  sub_id: string;
}
interface WireClientPing {
  type: 'PING';
}

type WireClientMessage =
  | WireClientAuth
  | WireClientSubscribe
  | WireClientUnsubscribe
  | WireClientPing;

interface WireServerAuthOk {
  type: 'AUTH_OK';
  conn_id: string;
  server_time: string;
}
interface WireServerSubscribed {
  type: 'SUBSCRIBED';
  sub_id: string;
  seq: number;
}
interface WireServerUnsubscribed {
  type: 'UNSUBSCRIBED';
  sub_id: string;
}
interface WireEventPayload {
  event_id: string;
  topic: string;
  event_type: string; // "inserted" | "updated" | "deleted"
  sequence: number;
  timestamp: string;
  payload: {
    table: string;
    schema: string;
    operation: string; // "INSERT" | "UPDATE" | "DELETE"
    data: Record<string, unknown>;
    old_data: Record<string, unknown> | null;
  };
}
interface WireServerEvent {
  type: 'EVENT';
  sub_id: string;
  event: WireEventPayload;
}
interface WireServerPong {
  type: 'PONG';
  server_time: string;
}
interface WireServerError {
  type: 'ERROR';
  code: string;
  message: string;
}

type WireServerMessage =
  | WireServerAuthOk
  | WireServerSubscribed
  | WireServerUnsubscribed
  | WireServerEvent
  | WireServerPong
  | WireServerError;

// ── Internal types ─────────────────────────────────────────────────

type EventCallback<T = Record<string, unknown>> = (event: RealtimeEvent<T>) => void;

interface SubscriptionEntry {
  subId: string;
  topic: string;
  callbacks: Map<string, EventCallback>;
  eventFilter?: RealtimeEventType;
}

// ── Client ─────────────────────────────────────────────────────────

export class RealtimeClient {
  private ws: WebSocket | null = null;
  private readonly wsUrl: string;
  private readonly subscriptions = new Map<string, SubscriptionEntry>();
  private readonly stateCallbacks = new Set<StateCallback>();
  private _state: ConnectionState = 'disconnected';
  private _connId: string | null = null;
  private _authenticated = false;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private reconnectAttempts = 0;
  private readonly maxReconnectAttempts = 15;
  private readonly baseReconnectDelay = 1000;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private disposed = false;
  private lastToken: string | null = null;

  constructor(url?: string) {
    const base = url || SUPABASE_URL;
    const wsProtocol = base.startsWith('https') ? 'wss' : 'ws';
    const host = base.replace(/^https?:\/\//, '');
    this.wsUrl = `${wsProtocol}://${host}/realtime/v1/ws`;
  }

  /** Current connection state */
  get state(): ConnectionState {
    return this._state;
  }

  /** Connection ID assigned by the server after AUTH_OK */
  get connectionId(): string | null {
    return this._connId;
  }

  /** Whether the AUTH handshake completed */
  get authenticated(): boolean {
    return this._authenticated;
  }

  /** Register a state change listener */
  onStateChange(cb: StateCallback): () => void {
    this.stateCallbacks.add(cb);
    return () => this.stateCallbacks.delete(cb);
  }

  private setState(s: ConnectionState) {
    this._state = s;
    this.stateCallbacks.forEach((cb) => cb(s));
  }

  // ── Connection ───────────────────────────────────────────────────

  /**
   * Open the WebSocket connection and perform AUTH handshake.
   * The token is sent as an in-band AUTH message (not a query param).
   */
  connect(accessToken?: string): void {
    if (this.disposed) return;
    if (this.ws?.readyState === WebSocket.OPEN) return;

    if (accessToken) this.lastToken = accessToken;
    const token = accessToken ?? this.lastToken ?? SUPABASE_ANON_KEY;

    this.setState('connecting');
    this._authenticated = false;

    try {
      this.ws = new WebSocket(this.wsUrl);
    } catch {
      this.setState('disconnected');
      this.scheduleReconnect();
      return;
    }

    this.ws.onopen = () => {
      this.reconnectAttempts = 0;
      // Step 1 of the protocol: send AUTH
      this.sendWire({ type: 'AUTH', token });
    };

    this.ws.onmessage = (ev) => {
      try {
        const data = JSON.parse(ev.data as string) as WireServerMessage;
        this.handleMessage(data);
      } catch {
        // ignore malformed
      }
    };

    this.ws.onclose = () => {
      this.stopHeartbeat();
      this._authenticated = false;
      if (!this.disposed) {
        this.setState('disconnected');
        this.scheduleReconnect();
      }
    };

    this.ws.onerror = () => {
      // onclose fires after onerror
    };
  }

  /** Cleanly close the connection and release resources */
  disconnect(): void {
    this.disposed = true;
    this.stopHeartbeat();
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.ws) {
      this.ws.onclose = null;
      this.ws.close();
      this.ws = null;
    }
    this._authenticated = false;
    this.subscriptions.clear();
    this.setState('disconnected');
  }

  // ── Subscribe / Unsubscribe ──────────────────────────────────────

  /**
   * Subscribe to a table's CDC events.
   *
   * @param table       Table name (e.g. "orders")
   * @param adapter     "postgresql" or "mongodb"
   * @param callback    Called for each normalised CDC event
   * @param eventFilter Optional: "INSERT" | "UPDATE" | "DELETE" | "*"
   * @returns           A subscription handle with `unsubscribe()`
   */
  subscribe<T = Record<string, unknown>>(
    table: string,
    adapter: RealtimeAdapter,
    callback: EventCallback<T>,
    eventFilter?: RealtimeEventType,
  ): RealtimeSubscription {
    const prefix = adapter === 'mongodb' ? 'mongo' : 'pg';

    // Build topic with glob for all event types on this table
    let topic: string;
    if (eventFilter && eventFilter !== '*') {
      const map: Record<string, string> = {
        INSERT: 'inserted',
        UPDATE: 'updated',
        DELETE: 'deleted',
      };
      topic = `${prefix}/${table}/${map[eventFilter] ?? '*'}`;
    } else {
      topic = `${prefix}/${table}/*`;
    }

    const subId = crypto.randomUUID();
    const callbackId = crypto.randomUUID();

    const entry: SubscriptionEntry = {
      subId,
      topic,
      callbacks: new Map([[callbackId, callback as EventCallback]]),
      eventFilter,
    };
    this.subscriptions.set(subId, entry);

    // Send SUBSCRIBE if already authenticated
    if (this._authenticated && this.ws?.readyState === WebSocket.OPEN) {
      this.sendWire({ type: 'SUBSCRIBE', sub_id: subId, topic });
    }

    return {
      channel: topic,
      subId,
      unsubscribe: () => {
        entry.callbacks.delete(callbackId);
        if (entry.callbacks.size === 0) {
          this.subscriptions.delete(subId);
          if (this.ws?.readyState === WebSocket.OPEN) {
            this.sendWire({ type: 'UNSUBSCRIBE', sub_id: subId });
          }
        }
      },
    };
  }

  /**
   * Subscribe to ALL CDC events for an adapter (all tables).
   * Useful for admin dashboards, log viewers, etc.
   */
  subscribeAll<T = Record<string, unknown>>(
    adapter: RealtimeAdapter,
    callback: EventCallback<T>,
  ): RealtimeSubscription {
    const prefix = adapter === 'mongodb' ? 'mongo' : 'pg';
    const topic = `${prefix}/**`;
    const subId = crypto.randomUUID();
    const callbackId = crypto.randomUUID();

    const entry: SubscriptionEntry = {
      subId,
      topic,
      callbacks: new Map([[callbackId, callback as EventCallback]]),
    };
    this.subscriptions.set(subId, entry);

    if (this._authenticated && this.ws?.readyState === WebSocket.OPEN) {
      this.sendWire({ type: 'SUBSCRIBE', sub_id: subId, topic });
    }

    return {
      channel: topic,
      subId,
      unsubscribe: () => {
        this.subscriptions.delete(subId);
        if (this.ws?.readyState === WebSocket.OPEN) {
          this.sendWire({ type: 'UNSUBSCRIBE', sub_id: subId });
        }
      },
    };
  }

  // ── Private ──────────────────────────────────────────────────────

  private sendWire(msg: WireClientMessage): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(msg));
    }
  }

  private handleMessage(msg: WireServerMessage): void {
    switch (msg.type) {
      case 'AUTH_OK':
        this._connId = msg.conn_id;
        this._authenticated = true;
        this.setState('connected');
        this.startHeartbeat();
        // Now that we're authenticated, send all pending subscriptions
        this.subscriptions.forEach((entry) => {
          this.sendWire({
            type: 'SUBSCRIBE',
            sub_id: entry.subId,
            topic: entry.topic,
          });
        });
        break;

      case 'SUBSCRIBED':
        // Subscription confirmed
        break;

      case 'UNSUBSCRIBED':
        break;

      case 'EVENT':
        this.handleEvent(msg);
        break;

      case 'PONG':
        break;

      case 'ERROR':
        console.warn(`[RealtimeClient] Server error: ${msg.code} — ${msg.message}`);
        break;
    }
  }

  /**
   * Transform a wire EVENT into a normalised RealtimeEvent
   * and dispatch to **all** subscriptions whose topic matches.
   *
   * The server may or may not populate `sub_id`, so we always
   * resolve matching subscriptions by comparing the event's topic
   * against each subscription's glob pattern.
   */
  private handleEvent(msg: WireServerEvent): void {
    const p = msg.event.payload;
    if (!p || typeof p.table !== 'string') return;

    // Map the Rust event_type ("inserted"→INSERT, etc.)
    const opMap: Record<string, 'INSERT' | 'UPDATE' | 'DELETE'> = {
      inserted: 'INSERT',
      updated: 'UPDATE',
      deleted: 'DELETE',
      INSERT: 'INSERT',
      UPDATE: 'UPDATE',
      DELETE: 'DELETE',
    };
    const operation = opMap[msg.event.event_type] ?? opMap[p.operation];
    if (!operation) return;

    const normalised: RealtimeEvent = {
      type: operation,
      schema: p.schema ?? 'public',
      table: p.table,
      record: (p.data ?? {}) as Record<string, unknown>,
      old_record: (p.old_data ?? null) as Record<string, unknown> | null,
      timestamp: new Date(msg.event.timestamp).getTime() / 1000,
    };

    const eventTopic = msg.event.topic; // e.g. "pg/working_hours/updated"

    // Find all subscriptions whose topic glob matches this event
    this.subscriptions.forEach((entry) => {
      if (!topicMatches(entry.topic, eventTopic)) return;

      // Apply optional event filter
      if (entry.eventFilter && entry.eventFilter !== '*' && entry.eventFilter !== operation) {
        return;
      }

      entry.callbacks.forEach((cb) => cb(normalised));
    });
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      this.sendWire({ type: 'PING' });
    }, 30_000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  private scheduleReconnect(): void {
    if (this.disposed) return;
    if (this.reconnectAttempts >= this.maxReconnectAttempts) return;

    this.setState('reconnecting');
    const delay = Math.min(this.baseReconnectDelay * 2 ** this.reconnectAttempts, 30_000);
    this.reconnectAttempts++;

    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
  }
}

// ── Helpers ────────────────────────────────────────────────────────

/**
 * Match an event topic against a subscription glob pattern.
 *
 * Supported wildcards:
 *   `*`  — matches exactly one path segment
 *   `**` — matches zero or more path segments (must be a full segment)
 *
 * Examples:
 *   topicMatches("pg/orders/*",       "pg/orders/inserted")  → true
 *   topicMatches("pg/orders/updated", "pg/orders/updated")   → true
 *   topicMatches("pg/**",             "pg/orders/inserted")  → true
 *   topicMatches("pg/orders/*",       "pg/menus/inserted")   → false
 */
function topicMatches(pattern: string, topic: string): boolean {
  const pat = pattern.split('/');
  const top = topic.split('/');

  let pi = 0;
  let ti = 0;
  while (pi < pat.length && ti < top.length) {
    if (pat[pi] === '**') {
      // trailing ** matches everything remaining
      if (pi === pat.length - 1) return true;
      // try matching rest of pattern from every remaining position
      for (let k = ti; k <= top.length; k++) {
        if (topicMatches(pat.slice(pi + 1).join('/'), top.slice(k).join('/'))) {
          return true;
        }
      }
      return false;
    }
    if (pat[pi] !== '*' && pat[pi] !== top[ti]) return false;
    pi++;
    ti++;
  }
  // consume trailing ** in pattern
  while (pi < pat.length && pat[pi] === '**') pi++;
  return pi === pat.length && ti === top.length;
}

// ── Singleton ──────────────────────────────────────────────────────

let _instance: RealtimeClient | null = null;

/** Get (or create) the shared RealtimeClient singleton */
export function getRealtimeClient(): RealtimeClient {
  if (!_instance) {
    _instance = new RealtimeClient();
  }
  return _instance;
}
