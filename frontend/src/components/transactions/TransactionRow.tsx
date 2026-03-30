import React from 'react';
import {
  ListItem,
  ListItemIcon,
  ListItemText,
  Box,
  Typography,
  Divider,
} from '@mui/material';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import ReceiptIcon from '@mui/icons-material/Receipt';
import LocalAtmIcon from '@mui/icons-material/LocalAtm';
import SavingsIcon from '@mui/icons-material/Savings';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import { Transaction, TransactionType } from '../../types';
import { formatCurrency } from '../common/CurrencyDisplay';
import { format } from 'date-fns';
import { alpha } from '@mui/material/styles';

const typeConfig: Record<TransactionType, { icon: React.ReactNode; color: string; isDebit: boolean }> = {
  debit:          { icon: <ArrowUpwardIcon fontSize="small" />,   color: '#C62828', isDebit: true },
  credit:         { icon: <ArrowDownwardIcon fontSize="small" />, color: '#2E7D32', isDebit: false },
  transfer_in:    { icon: <SwapHorizIcon fontSize="small" />,     color: '#0277BD', isDebit: false },
  transfer_out:   { icon: <SwapHorizIcon fontSize="small" />,     color: '#E65100', isDebit: true },
  bill_payment:   { icon: <ReceiptIcon fontSize="small" />,       color: '#6A1B9A', isDebit: true },
  deposit:        { icon: <ArrowDownwardIcon fontSize="small" />, color: '#2E7D32', isDebit: false },
  fee:            { icon: <ErrorOutlineIcon fontSize="small" />,  color: '#C62828', isDebit: true },
  interest:       { icon: <SavingsIcon fontSize="small" />,       color: '#2E7D32', isDebit: false },
  atm_withdrawal: { icon: <LocalAtmIcon fontSize="small" />,      color: '#E65100', isDebit: true },
  p2p_sent:       { icon: <ArrowUpwardIcon fontSize="small" />,   color: '#C62828', isDebit: true },
  p2p_received:   { icon: <ArrowDownwardIcon fontSize="small" />, color: '#2E7D32', isDebit: false },
};

interface TransactionRowProps {
  transaction: Transaction;
  divider?: boolean;
}

export default function TransactionRow({ transaction, divider }: TransactionRowProps) {
  const cfg = typeConfig[transaction.type];
  const isPending = transaction.status === 'pending';
  const isFailed = transaction.status === 'failed';

  return (
    <>
      <ListItem
        disablePadding
        sx={{
          py: 1,
          px: 0,
          opacity: isFailed ? 0.6 : 1,
        }}
      >
        <ListItemIcon sx={{ minWidth: 44 }}>
          <Box
            sx={{
              width: 36,
              height: 36,
              borderRadius: '50%',
              bgcolor: alpha(cfg.color, 0.1),
              color: cfg.color,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {cfg.icon}
          </Box>
        </ListItemIcon>
        <ListItemText
          primary={
            <Typography variant="body2" fontWeight={500} noWrap>
              {transaction.merchantName ?? transaction.description}
            </Typography>
          }
          secondary={
            <Typography variant="caption" color="text.secondary">
              {format(new Date(transaction.date), 'MMM d, yyyy')}
              {isPending && ' · Pending'}
              {isFailed && ' · Failed'}
            </Typography>
          }
        />
        <Box textAlign="right" ml={1}>
          <Typography
            variant="body2"
            fontWeight={600}
            color={isFailed ? 'text.disabled' : cfg.isDebit ? 'error.main' : 'success.main'}
          >
            {cfg.isDebit ? '-' : '+'}{formatCurrency(transaction.amount)}
          </Typography>
        </Box>
      </ListItem>
      {divider && <Divider />}
    </>
  );
}
