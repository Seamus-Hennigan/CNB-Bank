import React from 'react';
import { Grid, TextField, MenuItem, Button, Box } from '@mui/material';
import { TransactionFilters, TransactionType, TransactionStatus } from '../../types';

const TX_TYPES: { value: TransactionType | ''; label: string }[] = [
  { value: '',             label: 'All Types' },
  { value: 'debit',        label: 'Debit' },
  { value: 'credit',       label: 'Credit' },
  { value: 'transfer_in',  label: 'Transfer In' },
  { value: 'transfer_out', label: 'Transfer Out' },
  { value: 'bill_payment', label: 'Bill Payment' },
  { value: 'deposit',      label: 'Deposit' },
  { value: 'fee',          label: 'Fee' },
  { value: 'interest',     label: 'Interest' },
  { value: 'atm_withdrawal', label: 'ATM Withdrawal' },
  { value: 'p2p_sent',     label: 'P2P Sent' },
  { value: 'p2p_received', label: 'P2P Received' },
];

const TX_STATUSES: { value: TransactionStatus | ''; label: string }[] = [
  { value: '',          label: 'All Statuses' },
  { value: 'completed', label: 'Completed' },
  { value: 'pending',   label: 'Pending' },
  { value: 'failed',    label: 'Failed' },
  { value: 'reversed',  label: 'Reversed' },
];

interface TransactionFilterProps {
  filters: TransactionFilters;
  onChange: (f: TransactionFilters) => void;
  onReset: () => void;
}

export default function TransactionFilter({ filters, onChange, onReset }: TransactionFilterProps) {
  const set = (key: keyof TransactionFilters) => (e: React.ChangeEvent<HTMLInputElement>) =>
    onChange({ ...filters, [key]: e.target.value });

  return (
    <Box mb={3}>
      <Grid container spacing={2}>
        <Grid item xs={12} sm={6} md={3}>
          <TextField fullWidth label="Search" value={filters.search} onChange={set('search')} placeholder="Description, merchant…" />
        </Grid>
        <Grid item xs={6} sm={3} md={2}>
          <TextField fullWidth label="Start Date" type="date" value={filters.startDate} onChange={set('startDate')} InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={6} sm={3} md={2}>
          <TextField fullWidth label="End Date" type="date" value={filters.endDate} onChange={set('endDate')} InputLabelProps={{ shrink: true }} />
        </Grid>
        <Grid item xs={6} sm={3} md={2}>
          <TextField fullWidth select label="Type" value={filters.type} onChange={set('type')}>
            {TX_TYPES.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
          </TextField>
        </Grid>
        <Grid item xs={6} sm={3} md={2}>
          <TextField fullWidth select label="Status" value={filters.status} onChange={set('status')}>
            {TX_STATUSES.map((o) => <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>)}
          </TextField>
        </Grid>
        <Grid item xs={12} sm={12} md={1} display="flex" alignItems="flex-end">
          <Button fullWidth onClick={onReset} variant="outlined" size="small">Reset</Button>
        </Grid>
      </Grid>
    </Box>
  );
}
