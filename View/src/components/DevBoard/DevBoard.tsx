/**
 * DevBoard - Unified Dashboard component
 * Single page with role-based content switching (SPA pattern)
 */

import { useState, useEffect, useMemo } from 'react';
import { useDevBoard } from './useDevBoard';
import { DevBoardHeader } from './DevBoardHeader';
import { DevBoardSidebar } from './DevBoardSidebar';
import { DevBoardContent } from './DevBoardContent';
import { GradientBackground } from './GradientBackground';
import { SettingsModal } from '../features/qa/settings';
import { ShellFab, ShellModal } from '../cloud-terminal';
import { getCategoriesForRole, getDefaultCategory } from './constants';
import { useMockData } from './useMockData';
import { ErrorBoundary } from '../ErrorBoundary';
import { TestCountProvider } from './TestCountContext';
import { RoleViewProvider, useRoleView } from './RoleViewContext';
import { getDefaultViewForRole } from '../layout/Sidebar';
import { usePortalAuth } from '../../portal_dashboard';
import { useTestRunner } from './useTestRunner';
import type { NavSection } from '../layout/Header/Header';
import './DevBoard.css';

export function DevBoard() {
  const { user } = usePortalAuth();
  // Set default view based on user role
  const defaultView = user?.role ? getDefaultViewForRole(user.role) : 'employee';

  return (
    <RoleViewProvider defaultView={defaultView}>
      <ErrorBoundary
        fallback={(error, reset) => (
          <div
            style={{
              minHeight: '100vh',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '1rem',
              background: '#0F0F1A',
              color: '#E5E7EB',
            }}
          >
            <h2 style={{ fontSize: '1.25rem', color: '#F87171' }}>Dashboard — erreur inattendue</h2>
            <p style={{ fontSize: '0.875rem', opacity: 0.7, maxWidth: 400, textAlign: 'center' }}>
              {error.message}
            </p>
            <div style={{ display: 'flex', gap: '0.75rem' }}>
              <button
                onClick={reset}
                style={{
                  padding: '0.5rem 1.25rem',
                  background: '#6366F1',
                  color: '#fff',
                  border: 'none',
                  borderRadius: 8,
                  cursor: 'pointer',
                }}
              >
                Réessayer
              </button>
              <button
                onClick={() => {
                  globalThis.location.href = '/';
                }}
                style={{
                  padding: '0.5rem 1.25rem',
                  background: 'transparent',
                  color: '#9CA3AF',
                  border: '1px solid #374151',
                  borderRadius: 8,
                  cursor: 'pointer',
                }}
              >
                Retour à l'accueil
              </button>
            </div>
          </div>
        )}
      >
        <DevBoardInner />
      </ErrorBoundary>
    </RoleViewProvider>
  );
}

function DevBoardInner() {
  const { currentView } = useRoleView();
  const [activeSection, setActiveSection] = useState<NavSection>('dashboard');
  const [isShellOpen, setIsShellOpen] = useState(false);
  const testRunner = useTestRunner();
  const {
    activeCategory,
    isSidebarCollapsed,
    isSettingsOpen,
    selectCategory,
    toggleSidebar,
    closeSettings,
  } = useDevBoard();

  // Reset category when view changes
  useEffect(() => {
    selectCategory(getDefaultCategory(currentView));
  }, [currentView, selectCategory]);

  // Get categories for current role view
  const baseCategories = useMemo(() => getCategoriesForRole(currentView), [currentView]);

  // Get scenario count dynamically from mock data (or real data if available)
  const scenarioCount = useMockData('scenarios').tests.length;

  // Add dynamic test count for dev view
  const categories = useMemo(() => {
    if (currentView !== 'dev') return baseCategories;
    return baseCategories.map((cat) => {
      if (cat.id === 'test-automatics') {
        return { ...cat, count: testRunner.metrics.total };
      }
      if (cat.id === 'scenarios') {
        return { ...cat, count: scenarioCount };
      }
      return cat;
    });
  }, [baseCategories, currentView, testRunner.metrics.total, scenarioCount]);

  // Keyboard shortcut: Ctrl+` to open terminal (desktop only, dev view only)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === '`' && globalThis.innerWidth > 768 && currentView === 'dev') {
        e.preventDefault();
        setIsShellOpen((prev) => !prev);
      }
    };
    globalThis.addEventListener('keydown', handleKeyDown);
    return () => globalThis.removeEventListener('keydown', handleKeyDown);
  }, [currentView]);

  return (
    <TestCountProvider value={{ testCount: testRunner.metrics.total }}>
      <div className="devboard">
        <GradientBackground />
        <DevBoardHeader
          activeSection={activeSection}
          onSectionChange={setActiveSection}
          categories={categories}
          activeCategory={activeCategory}
          onCategoryChange={selectCategory}
        />
        <section className="devboard-body">
          <DevBoardSidebar
            categories={categories}
            activeCategory={activeCategory}
            collapsed={isSidebarCollapsed}
            onSelectCategory={selectCategory}
            onToggleCollapse={toggleSidebar}
          />
          <DevBoardContent
            activeCategory={activeCategory}
            testRunner={testRunner}
            roleView={currentView}
          />
        </section>
        <SettingsModal isOpen={isSettingsOpen} onClose={closeSettings} />

        {/* Cloud Shell - Desktop only, dev view only */}
        {currentView === 'dev' && (
          <>
            <ShellFab onClick={() => setIsShellOpen(true)} />
            <ShellModal isOpen={isShellOpen} onClose={() => setIsShellOpen(false)} />
          </>
        )}
      </div>
    </TestCountProvider>
  );
}
