import React, { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem,
  Button, Alert, CircularProgress, InputAdornment,
} from '@mui/material';
import { NumericFormat } from 'react-number-format';
import { useAccounts } from '../hooks/useAccounts';
import { submitTransfer } from '../services/transfer.service';
import ConfirmDialog from '../components/common/ConfirmDialog';
import { formatCurrency } from '../components/common/CurrencyDisplay';

export default function TransferPage() {
  const { accounts } = useAccounts();
  const [fromId, setFromId] = useState('');
  const [toId, setToId] = useState('');
  const [amount, setAmount] = useState('');
  const [memo, setMemo] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const amountCents = Math.round(parseFloat(amount.replace(/,/g, '') || '0') * 100);
  const fromAccount = accounts.find((a) => a.id === fromId);
  const toAccount = accounts.find((a) => a.id === toId);
  const isValid = fromId && toId && fromId !== toId && amountCents > 0;

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await submitTransfer({ fromAccountId: fromId, toAccountId: toId, amount: amountCents, memo, scheduledDate: null });
      setSuccess(res.message);
      setConfirmOpen(false);
      setAmount(''); setMemo('');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Transfer failed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box maxWidth={600}>
      <Typography variant="h2" mb={0.5}>Transfer Money</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>Move funds between your accounts.</Typography>

      <Card>
        <CardContent>
          {success && <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess('')}>{success}</Alert>}
          {error && <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>{error}</Alert>}

          <TextField fullWidth select label="From Account" value={fromId} onChange={(e) => setFromId(e.target.value)} sx={{ mb: 2 }}>
            {accounts.map((a) => (
              <MenuItem key={a.id} value={a.id}>
                {a.nickname ?? a.maskedAccountNumber} — {formatCurrency(a.availableBalance)} available
              </MenuItem>
            ))}
          </TextField>

          <TextField fullWidth select label="To Account" value={toId} onChange={(e) => setToId(e.target.value)} sx={{ mb: 2 }}>
            {accounts.filter((a) => a.id !== fromId).map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.nickname ?? a.maskedAccountNumber}</MenuItem>
            ))}
          </TextField>

          <NumericFormat
            customInput={TextField}
            fullWidth label="Amount" value={amount}
            onValueChange={(v) => setAmount(v.value)}
            thousandSeparator prefix="$" decimalScale={2} fixedDecimalScale
            sx={{ mb: 2 }}
            InputProps={{ startAdornment: <InputAdornment position="start" /> }}
          />

          <TextField fullWidth label="Memo (optional)" value={memo} onChange={(e) => setMemo(e.target.value)} sx={{ mb: 3 }} />

          <Button fullWidth variant="contained" size="large" disabled={!isValid} onClick={() => setConfirmOpen(true)}>
            Review Transfer
          </Button>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirmOpen}
        title="Confirm Transfer"
        message={`Transfer ${formatCurrency(amountCents)} from ${fromAccount?.nickname ?? fromAccount?.maskedAccountNumber} to ${toAccount?.nickname ?? toAccount?.maskedAccountNumber}?`}
        confirmLabel="Transfer"
        loading={loading}
        onConfirm={handleSubmit}
        onCancel={() => setConfirmOpen(false)}
      />
    </Box>
  );
}
