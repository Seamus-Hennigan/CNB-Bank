import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Card, CardContent, Typography, List, ListItemButton,
  ListItemText, ListItemIcon, Box, Skeleton, Button,
} from '@mui/material';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import SavingsIcon from '@mui/icons-material/Savings';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import { Account } from '../../types';
import { formatCurrency } from '../common/CurrencyDisplay';

interface LinkedAccountMiniProps {
  accounts: Account[];
  loading?: boolean;
}

export default function LinkedAccountMini({ accounts, loading }: LinkedAccountMiniProps) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Typography variant="h4">My Accounts</Typography>
          <Button size="small" endIcon={<ArrowForwardIcon />} onClick={() => navigate('/accounts')}>
            Manage
          </Button>
        </Box>

        {loading ? (
          Array.from({ length: 2 }).map((_, i) => (
            <Box key={i} display="flex" gap={2} py={1.5} alignItems="center">
              <Skeleton variant="circular" width={36} height={36} />
              <Box flex={1}>
                <Skeleton variant="text" width="50%" />
                <Skeleton variant="text" width="40%" />
              </Box>
            </Box>
          ))
        ) : (
          <List disablePadding>
            {accounts.map((account) => (
              <ListItemButton
                key={account.id}
                onClick={() => navigate(`/accounts/${account.id}`)}
                sx={{ px: 1, borderRadius: 2, mb: 0.5 }}
              >
                <ListItemIcon sx={{ minWidth: 40 }}>
                  {account.type === 'savings'
                    ? <SavingsIcon color="primary" />
                    : <AccountBalanceIcon color="primary" />}
                </ListItemIcon>
                <ListItemText
                  primary={<Typography variant="body2" fontWeight={600}>{account.nickname ?? account.maskedAccountNumber}</Typography>}
                  secondary={account.maskedAccountNumber}
                />
                <Box textAlign="right">
                  <Typography variant="body2" fontWeight={600}>{formatCurrency(account.currentBalance)}</Typography>
                  <Typography variant="caption" color="text.secondary">{account.type}</Typography>
                </Box>
              </ListItemButton>
            ))}
          </List>
        )}
      </CardContent>
    </Card>
  );
}
