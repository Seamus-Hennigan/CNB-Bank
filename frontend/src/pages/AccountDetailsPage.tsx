import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box, Typography, Card, CardContent, Grid, Button,
  Divider, Chip, Skeleton,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { Account, Transaction } from '../types';
import { getAccountById } from '../services/account.service';
import { getTransactions } from '../services/transaction.service';
import { formatCurrency } from '../components/common/CurrencyDisplay';
import MaskedText from '../components/common/MaskedText';
import StatusChip from '../components/common/StatusChip';
import TransactionTable from '../components/transactions/TransactionTable';

export default function AccountDetailsPage() {
  const { accountId } = useParams<{ accountId: string }>();
  const navigate = useNavigate();
  const [account, setAccount] = useState<Account | null>(null);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [txnLoading, setTxnLoading] = useState(true);

  useEffect(() => {
    if (!accountId) return;
    getAccountById(accountId).then(setAccount).finally(() => setLoading(false));
    getTransactions(accountId)
      .then((txns) => setTransactions(txns.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())))
      .finally(() => setTxnLoading(false));
  }, [accountId]);

  return (
    <Box>
      <Button startIcon={<ArrowBackIcon />} onClick={() => navigate('/accounts')} sx={{ mb: 2 }}>
        Back to Accounts
      </Button>

      {loading ? (
        <Skeleton variant="rectangular" height={200} sx={{ borderRadius: 2, mb: 3 }} />
      ) : account ? (
        <Card sx={{ mb: 3, bgcolor: '#0A2463', color: 'white' }}>
          <CardContent>
            <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
              <Box display="flex" gap={1} alignItems="center">
                <Chip label={account.type} size="small" sx={{ bgcolor: 'rgba(255,255,255,0.15)', color: 'white' }} />
                <StatusChip status={account.status} />
              </Box>
              <MaskedText masked={account.maskedAccountNumber} revealed={account.accountNumber}
                typographyProps={{ color: 'rgba(255,255,255,0.7)' }} />
            </Box>

            <Typography variant="h6" sx={{ color: 'rgba(255,255,255,0.7)', mb: 0.5 }}>
              {account.nickname ?? 'Account'}
            </Typography>
            <Typography variant="h1" color="white" fontWeight={700} mb={2}>
              {formatCurrency(account.currentBalance)}
            </Typography>

            <Divider sx={{ borderColor: 'rgba(255,255,255,0.12)', mb: 2 }} />

            <Grid container spacing={3}>
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Available</Typography>
                <Typography variant="h5" color="white" fontWeight={600}>{formatCurrency(account.availableBalance)}</Typography>
              </Grid>
              {account.interestRate && (
                <Grid item xs={6} sm={3}>
                  <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>APY</Typography>
                  <Typography variant="h5" sx={{ color: '#D4AF37', fontWeight: 600 }}>{account.interestRate}%</Typography>
                </Grid>
              )}
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Routing #</Typography>
                <MaskedText masked={account.maskedRoutingNumber} revealed={account.routingNumber}
                  typographyProps={{ color: 'rgba(255,255,255,0.8)' }} />
              </Grid>
              <Grid item xs={6} sm={3}>
                <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Opened</Typography>
                <Typography variant="body2" color="white">{new Date(account.openedDate).toLocaleDateString()}</Typography>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      ) : null}

      <Typography variant="h3" mb={2}>Transaction History</Typography>
      <TransactionTable transactions={transactions} loading={txnLoading} />
    </Box>
  );
}
