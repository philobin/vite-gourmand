/**
 * PublicDataContext — Centralised data fetching for public pages.
 *
 * All shared read-only data (site info, working hours, reviews, stats) is
 * fetched **once** when PublicSPA mounts and exposed via context so that
 * Footer, Home, Contact … receive it via `usePublicData()` instead of each
 * component firing its own API calls on every page navigation.
 */

import {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from 'react';
import {
  fetchSiteInfo,
  fetchWorkingHours,
  fetchApprovedReviews,
  fetchReviewStats,
  type SiteInfo,
  type WorkingHour,
  type PublicReview,
  type ReviewStats,
} from '../services/public';
import { REALTIME_URL, getRealtimeClient } from '../lib/realtime';

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */

export interface PublicData {
  siteInfo: SiteInfo | null;
  workingHours: WorkingHour[];
  reviews: PublicReview[];
  reviewStats: ReviewStats | null;
  loading: boolean;
}

const defaultValue: PublicData = {
  siteInfo: null,
  workingHours: [],
  reviews: [],
  reviewStats: null,
  loading: false,
};

/* ------------------------------------------------------------------ */
/*  Context & hook                                                     */
/* ------------------------------------------------------------------ */

const PublicDataCtx = createContext<PublicData>(defaultValue);

// eslint-disable-next-line react-refresh/only-export-components
export function usePublicData(): PublicData {
  return useContext(PublicDataCtx);
}

/* ------------------------------------------------------------------ */
/*  Provider                                                           */
/* ------------------------------------------------------------------ */

const DAY_ORDER = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

function logPublicDataWarning(message: string, err: unknown) {
  if (import.meta.env.DEV) {
    console.warn(message, err);
  }
}

const REFETCH_DEBOUNCE_MS = 300;

/**
 * Live public data: re-fetch a slice when the realtime engine reports a change
 * on the table behind it. Opt-in via VITE_REALTIME_URL; without it nothing
 * connects. Caveat: events are only a trigger (full re-fetch, no patching), so
 * a burst costs one request per slice after the debounce, not one per event.
 */
function usePublicRealtimeRefetch(setData: Dispatch<SetStateAction<PublicData>>) {
  const timers = useRef<Record<string, ReturnType<typeof setTimeout>>>({});

  useEffect(() => {
    if (!REALTIME_URL) return;
    const client = getRealtimeClient();
    client.connect();
    const pending = timers.current;

    const refetchOn = (table: string, key: string, run: () => Promise<Partial<PublicData>>) =>
      client.subscribe(table, 'postgresql', () => {
        globalThis.clearTimeout(pending[key]);
        pending[key] = globalThis.setTimeout(() => {
          run()
            .then((slice) => setData((prev) => ({ ...prev, ...slice })))
            .catch((err) =>
              logPublicDataWarning(`[PublicDataProvider] Realtime refetch ${key} failed:`, err),
            );
        }, REFETCH_DEBOUNCE_MS);
      });

    const refetchHours = async () => {
      const hours = await fetchWorkingHours();
      hours.sort((a, b) => DAY_ORDER.indexOf(a.day) - DAY_ORDER.indexOf(b.day));
      return { workingHours: hours };
    };
    const refetchReviews = async () => {
      const [reviews, reviewStats] = await Promise.all([
        fetchApprovedReviews(1, 20),
        fetchReviewStats(),
      ]);
      return { reviews, reviewStats };
    };
    const refetchSiteInfo = async () => ({ siteInfo: await fetchSiteInfo() });

    const subs = [
      refetchOn('working_hours', 'hours', refetchHours),
      refetchOn('reviews', 'reviews', refetchReviews),
      refetchOn('companies', 'siteInfo', refetchSiteInfo),
      refetchOn('company_owners', 'siteInfo', refetchSiteInfo),
    ];

    return () => {
      subs.forEach((sub) => sub.unsubscribe());
      Object.values(pending).forEach((timer) => globalThis.clearTimeout(timer));
    };
  }, [setData]);
}

export function PublicDataProvider({ children }: Readonly<{ children: ReactNode }>) {
  const [data, setData] = useState<PublicData>(defaultValue);

  useEffect(() => {
    let cancelled = false;

    const loadHeroData = async () => {
      try {
        const [info, stats] = await Promise.all([fetchSiteInfo(), fetchReviewStats()]);

        if (cancelled) return;

        setData((prev) => ({
          ...prev,
          siteInfo: info,
          reviewStats: stats,
        }));
      } catch (err) {
        logPublicDataWarning('[PublicDataProvider] Failed to fetch hero public data:', err);
      }
    };

    const loadDeferredData = async () => {
      try {
        const [hours, rawReviews] = await Promise.all([
          fetchWorkingHours(),
          fetchApprovedReviews(1, 20),
        ]);

        if (cancelled) return;

        // Sort hours by weekday
        hours.sort((a, b) => DAY_ORDER.indexOf(a.day) - DAY_ORDER.indexOf(b.day));

        setData((prev) => ({
          ...prev,
          workingHours: hours,
          reviews: rawReviews,
          loading: false,
        }));
      } catch (err) {
        logPublicDataWarning('[PublicDataProvider] Failed to fetch deferred public data:', err);
        if (!cancelled) {
          setData((prev) => ({ ...prev, loading: false }));
        }
      }
    };

    const heroTimer = globalThis.setTimeout(loadHeroData, 5000);
    const deferredTimer = globalThis.setTimeout(loadDeferredData, 8000);

    return () => {
      cancelled = true;
      globalThis.clearTimeout(heroTimer);
      globalThis.clearTimeout(deferredTimer);
    };
  }, []); // fetch once on mount

  usePublicRealtimeRefetch(setData);

  return <PublicDataCtx.Provider value={data}>{children}</PublicDataCtx.Provider>;
}
