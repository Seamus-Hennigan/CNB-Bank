import React from 'react';
import { Box, Typography, Grid, Skeleton } from '@mui/material';
import { useAccounts } from '../hooks/useAccounts';
import AccountCard from '../components/accounts/AccountCard';

export default function LinkedAccountsPage() {
  const { accounts, loading } = useAccounts();

  return (
    <Box>
      <Typography variant="h2" mb={0.5}>Accounts</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>
        Manage and view all your linked accounts.
      </Typography>

      <Grid container spacing={3}>
        {loading
          ? Array.from({ length: 2 }).map((_, i) => (
              <Grid item xs={12} key={i}>
                <Skeleton variant="rectangular" height={140} sx={{ borderRadius: 2 }} />
              </Grid>
            ))
          : accounts.map((account) => (
              <Grid item xs={12} key={account.id}>
                <AccountCard account={account} />
              </Grid>
            ))}
      </Grid>
    </Box>
  );
}
