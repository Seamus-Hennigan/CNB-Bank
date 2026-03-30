import React, { useEffect, useState } from 'react';
import { Box, Typography, Grid } from '@mui/material';
import { useAuth } from '../hooks/useAuth';
import { useAccounts } from '../hooks/useAccounts';
import { Account, Transaction } from '../types';
import { getRecentTransactions } from '../services/transaction.service';
import AccountOverviewCard from '../components/dashboard/AccountOverviewCard';
import QuickActionButtons from '../components/dashboard/QuickActionButtons';
import RecentTransactions from '../components/dashboard/RecentTransactions';
import LinkedAccountMini from '../components/accounts/LinkedAccountMini';

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

export default function DashboardPage() {
  const { user } = useAuth();
  const { accounts, loading: accountsLoading } = useAccounts();
  const [primaryAccount, setPrimaryAccount] = useState<Account | null>(null);
  const [recentTxns, setRecentTxns] = useState<Transaction[]>([]);
  const [txnsLoading, setTxnsLoading] = useState(true);

  useEffect(() => {
    if (accounts.length > 0) {
      const primary = accounts.find((a) => a.type === 'checking') ?? accounts[0];
      setPrimaryAccount(primary);
      getRecentTransactions(primary.id, 8)
        .then(setRecentTxns)
        .finally(() => setTxnsLoading(false));
    }
  }, [accounts]);

  const greeting = `${getGreeting()}, ${user?.given_name ?? 'there'}`;

  return (
    <Box>
      <Typography variant="h2" mb={0.5}>{greeting}</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>
        Here's a summary of your accounts.
      </Typography>

      <AccountOverviewCard account={primaryAccount} loading={accountsLoading} />
      <QuickActionButtons />

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <RecentTransactions transactions={recentTxns} loading={txnsLoading} accountId={primaryAccount?.id} />
        </Grid>
        <Grid item xs={12} md={4}>
          <LinkedAccountMini accounts={accounts} loading={accountsLoading} />
        </Grid>
      </Grid>
    </Box>
  );
}
