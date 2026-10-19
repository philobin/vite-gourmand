/**
 * ErrorBoundary — Generic React error boundary.
 *
 * Catches render-time errors in the sub-tree and shows a fallback UI
 * instead of crashing the entire application to a white screen.
 *
 * Usage:
 * ```tsx
 * <ErrorBoundary fallback={(error, reset) => <CrashScreen error={error} onRetry={reset} />}>
 *   <App />
 * </ErrorBoundary>
 * ```
 */

import { Component, type ErrorInfo, type ReactNode } from 'react';

// ── Types ──────────────────────────────────────────────────────────

export interface ErrorBoundaryProps {
  children: ReactNode;
  /** Custom fallback — string of a render function receiving the error and a reset callback */
  fallback?: ReactNode | ((error: Error, reset: () => void) => ReactNode);
  /** Optional error callback for logging / telemetry */
  onError?: (error: Error, info: ErrorInfo) => void;
}

interface ErrorBoundaryState {
  error: Error | null;
}

// ── Component ──────────────────────────────────────────────────────

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  override state: ErrorBoundaryState = { error: null };

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { error };
  }

  override componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ErrorBoundary] Uncaught render error:', error, info.componentStack);
    this.props.onError?.(error, info);
  }

  private readonly reset = () => this.setState({ error: null });

  override render() {
    const { error } = this.state;
    if (!error) return this.props.children;

    // Custom fallback (render function)
    if (typeof this.props.fallback === 'function') {
      return this.props.fallback(error, this.reset);
    }

    // Custom fallback (static element)
    if (this.props.fallback) return this.props.fallback;

    // Default fallback UI
    return (
      <div
        style={{
          minHeight: '60vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '2rem',
          fontFamily: 'system-ui, -apple-system, sans-serif',
          color: '#333',
          textAlign: 'center',
        }}
      >
        <div
          style={{
            background: '#FEF2F2',
            border: '1px solid #FECACA',
            borderRadius: '12px',
            padding: '2rem 2.5rem',
            maxWidth: '480px',
            width: '100%',
          }}
        >
          <h2 style={{ margin: '0 0 0.5rem', fontSize: '1.25rem', color: '#991B1B' }}>
            Une erreur est survenue
          </h2>
          <p style={{ margin: '0 0 1.5rem', color: '#7F1D1D', fontSize: '0.875rem', opacity: 0.8 }}>
            {error.message || 'Erreur inattendue'}
          </p>
          <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'center' }}>
            <button
              onClick={this.reset}
              style={{
                padding: '0.5rem 1.25rem',
                background: '#DC2626',
                color: '#fff',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '0.875rem',
                fontWeight: 600,
              }}
            >
              Réessayer
            </button>
            <button
              onClick={() => globalThis.location.reload()}
              style={{
                padding: '0.5rem 1.25rem',
                background: '#fff',
                color: '#333',
                border: '1px solid #D1D5DB',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '0.875rem',
              }}
            >
              Recharger la page
            </button>
          </div>
        </div>
      </div>
    );
  }
}
