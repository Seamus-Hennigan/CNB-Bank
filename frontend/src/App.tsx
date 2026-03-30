import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { theme } from './theme/theme';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import AppShell from './components/layout/AppShell';

import LoginPage from './pages/LoginPage';
import CallbackPage from './pages/CallbackPage';
import DashboardPage from './pages/DashboardPage';
import TransactionHistoryPage from './pages/TransactionHistoryPage';
import TransferPage from './pages/TransferPage';
import BillPayPage from './pages/BillPayPage';
import DepositPage from './pages/DepositPage';
import SendMoneyPage from './pages/SendMoneyPage';
import LinkedAccountsPage from './pages/LinkedAccountsPage';
import AccountDetailsPage from './pages/AccountDetailsPage';
import ProfilePage from './pages/ProfilePage';
import SecurityPage from './pages/SecurityPage';
import NotificationsPage from './pages/NotificationsPage';
import NotFoundPage from './pages/NotFoundPage';

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public routes */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/callback" element={<CallbackPage />} />
            <Route path="/" element={<Navigate to="/dashboard" replace />} />

            {/* Protected routes */}
            <Route
              element={
                <ProtectedRoute>
                  <AppShell />
                </ProtectedRoute>
              }
            >
              <Route path="/dashboard"    element={<DashboardPage />} />
              <Route path="/transactions" element={<TransactionHistoryPage />} />
              <Route path="/transfer"     element={<TransferPage />} />
              <Route path="/bill-pay"     element={<BillPayPage />} />
              <Route path="/deposit"      element={<DepositPage />} />
              <Route path="/send-money"   element={<SendMoneyPage />} />
              <Route path="/accounts"     element={<LinkedAccountsPage />} />
              <Route path="/accounts/:accountId" element={<AccountDetailsPage />} />
              <Route path="/profile"      element={<ProfilePage />} />
              <Route path="/security"     element={<SecurityPage />} />
              <Route path="/notifications" element={<NotificationsPage />} />
              <Route path="*"             element={<NotFoundPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}
