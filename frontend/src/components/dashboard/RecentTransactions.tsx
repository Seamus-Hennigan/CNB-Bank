import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Card,
  CardContent,
  Typography,
  List,
  Button,
  Box,
  Skeleton,
} from '@mui/material';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import TransactionRow from '../transactions/TransactionRow';
import { Transaction } from '../../types';

interface RecentTransactionsProps {
  transactions: Transaction[];
  loading?: boolean;
  accountId?: string;
}

export default function RecentTransactions({ transactions, loading, accountId }: RecentTransactionsProps) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Typography variant="h4">Recent Transactions</Typography>
          <Button
            size="small"
            endIcon={<ArrowForwardIcon />}
            onClick={() => navigate(accountId ? `/transactions?account=${accountId}` : '/transactions')}
          >
            View All
          </Button>
        </Box>

        {loading ? (
          Array.from({ length: 5 }).map((_, i) => (
            <Box key={i} display="flex" alignItems="center" gap={2} py={1}>
              <Skeleton variant="circular" width={36} height={36} />
              <Box flex={1}>
                <Skeleton variant="text" width="60%" />
                <Skeleton variant="text" width="30%" />
              </Box>
              <Skeleton variant="text" width={60} />
            </Box>
          ))
        ) : transactions.length === 0 ? (
          <Typography variant="body2" color="text.secondary" textAlign="center" py={4}>
            No recent transactions
          </Typography>
        ) : (
          <List disablePadding>
            {transactions.map((txn, idx) => (
              <TransactionRow
                key={txn.id}
                transaction={txn}
                divider={idx < transactions.length - 1}
              />
            ))}
          </List>
        )}
      </CardContent>
    </Card>
  );
}
