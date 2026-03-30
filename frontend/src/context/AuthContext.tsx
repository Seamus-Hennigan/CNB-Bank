import React, { createContext, useReducer, useEffect, useCallback } from 'react';
import { AuthState, AuthAction, AuthUser } from '../types';
import { loginWithCognito, logoutFromCognito, getCurrentUser, hasActiveSession } from '../services/auth.service';
import { isMockMode } from '../services/mock/mock.service';
import { mockCustomer } from '../services/mock/mock-customer';

// ── Reducer ────────────────────────────────────────────────────────────────
const initialState: AuthState = {
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
};

function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload, isAuthenticated: true, isLoading: false, error: null };
    case 'LOGOUT':
      return { ...initialState, isLoading: false };
    case 'SET_ERROR':
      return { ...state, error: action.payload, isLoading: false };
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'CLEAR_ERROR':
      return { ...state, error: null };
    default:
      return state;
  }
}

// ── Mock helpers ───────────────────────────────────────────────────────────
const MOCK_USER: AuthUser = {
  sub: 'mock-sub-001',
  email: mockCustomer.email,
  given_name: mockCustomer.given_name,
  family_name: mockCustomer.family_name,
  groups: [],
};

const MOCK_SESSION_KEY = 'cnb_mock_session';

// ── Context ────────────────────────────────────────────────────────────────
interface AuthContextValue extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  confirmMfa: (code: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

// ── Provider ───────────────────────────────────────────────────────────────
export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Restore session on mount
  useEffect(() => {
    (async () => {
      try {
        if (isMockMode()) {
          const stored = sessionStorage.getItem(MOCK_SESSION_KEY);
          if (stored) dispatch({ type: 'SET_USER', payload: MOCK_USER });
          else dispatch({ type: 'SET_LOADING', payload: false });
          return;
        }
        const active = await hasActiveSession();
        if (active) {
          const user = await getCurrentUser();
          if (user) dispatch({ type: 'SET_USER', payload: user });
          else dispatch({ type: 'SET_LOADING', payload: false });
        } else {
          dispatch({ type: 'SET_LOADING', payload: false });
        }
      } catch {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    })();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      if (isMockMode()) {
        if (password !== 'Password123!') throw new Error('Incorrect username or password.');
        sessionStorage.setItem(MOCK_SESSION_KEY, '1');
        dispatch({ type: 'SET_USER', payload: MOCK_USER });
        return;
      }
      await loginWithCognito(email, password);
      const user = await getCurrentUser();
      if (user) dispatch({ type: 'SET_USER', payload: user });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Login failed. Please try again.';
      dispatch({ type: 'SET_ERROR', payload: msg });
    }
  }, []);

  const confirmMfa = useCallback(async (_code: string) => {
    // MFA confirmation handled by Amplify hub; this is a stub for custom flows
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const user = await getCurrentUser();
      if (user) dispatch({ type: 'SET_USER', payload: user });
    } catch {
      dispatch({ type: 'SET_ERROR', payload: 'MFA verification failed.' });
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      if (isMockMode()) {
        sessionStorage.removeItem(MOCK_SESSION_KEY);
      } else {
        await logoutFromCognito();
      }
    } finally {
      dispatch({ type: 'LOGOUT' });
    }
  }, []);

  const clearError = useCallback(() => dispatch({ type: 'CLEAR_ERROR' }), []);

  return (
    <AuthContext.Provider value={{ ...state, login, confirmMfa, logout, clearError }}>
      {children}
    </AuthContext.Provider>
  );
}
