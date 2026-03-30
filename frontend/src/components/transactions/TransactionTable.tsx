import React from 'react';
import {
  Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Paper, Typography, Box, Skeleton,
} from '@mui/material';
import { Transaction, TransactionType } from '../../types';
import { formatCurrency } from '../common/CurrencyDisplay';
import StatusChip from '../common/StatusChip';
import { format } from 'date-fns';
import { alpha } from '@mui/material/styles';

const DEBIT_TYPES: TransactionType[] = [
  'debit', 'transfer_out', 'bill_payment', 'fee', 'atm_withdrawal', 'p2p_sent',
];

interface TransactionTableProps {
  transactions: Transaction[];
  loading?: boolean;
}

export default function TransactionTable({ transactions, loading }: TransactionTableProps) {
  if (loading) {
    return (
      <Box>
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} variant="rectangular" height={52} sx={{ mb: 1, borderRadius: 1 }} />
        ))}
      </Box>
    );
  }

  if (transactions.length === 0) {
    return (
      <Box py={8} textAlign="center">
        <Typography color="text.secondary">No transactions found matching your filters.</Typography>
      </Box>
    );
  }

  return (
    <TableContainer component={Paper} variant="outlined" sx={{ borderRadius: 2 }}>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Date</TableCell>
            <TableCell>Description</TableCell>
            <TableCell>Type</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right">Amount</TableCell>
            <TableCell align="right">Balance</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {transactions.map((txn) => {
            const isDebit = DEBIT_TYPES.includes(txn.type);
            return (
              <TableRow
                key={txn.id}
                sx={{ '&:hover': { bgcolor: alpha('#0A2463', 0.03) } }}
              >
                <TableCell>
                  <Typography variant="caption" noWrap>
                    {format(new Date(txn.date), 'MMM d, yyyy')}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" fontWeight={500}>
                    {txn.merchantName ?? txn.description}
                  </Typography>
                  {txn.merchantName && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      {txn.description}
                    </Typography>
                  )}
                </TableCell>
                <TableCell>
                  <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'capitalize' }}>
                    {txn.type.replace(/_/g, ' ')}
                  </Typography>
                </TableCell>
                <TableCell>
                  <StatusChip status={txn.status} />
                </TableCell>
                <TableCell align="right">
                  <Typography
                    variant="body2"
                    fontWeight={600}
                    color={txn.status === 'failed' ? 'text.disabled' : isDebit ? 'error.main' : 'success.main'}
                  >
                    {isDebit ? '-' : '+'}{formatCurrency(txn.amount)}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="caption" color="text.secondary">
                    {formatCurrency(txn.runningBalance)}
                  </Typography>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
