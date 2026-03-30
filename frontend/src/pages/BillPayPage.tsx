import React, { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem,
  Button, Alert, InputAdornment,
} from '@mui/material';
import { NumericFormat } from 'react-number-format';
import { useAccounts } from '../hooks/useAccounts';
import { submitBillPay } from '../services/transfer.service';
import ConfirmDialog from '../components/common/ConfirmDialog';
import { formatCurrency } from '../components/common/CurrencyDisplay';
import { format } from 'date-fns';

export default function BillPayPage() {
  const { accounts } = useAccounts();
  const [fromId, setFromId] = useState('');
  const [payee, setPayee] = useState('');
  const [amount, setAmount] = useState('');
  const [memo, setMemo] = useState('');
  const [scheduledDate, setScheduledDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const amountCents = Math.round(parseFloat(amount.replace(/,/g, '') || '0') * 100);
  const isValid = fromId && payee && amountCents > 0 && scheduledDate;

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await submitBillPay({ fromAccountId: fromId, payee, amount: amountCents, memo, scheduledDate });
      setSuccess(res.message);
      setConfirmOpen(false);
      setPayee(''); setAmount(''); setMemo('');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Bill payment failed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box maxWidth={600}>
      <Typography variant="h2" mb={0.5}>Pay a Bill</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>Schedule a bill payment.</Typography>

      <Card>
        <CardContent>
          {success && <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess('')}>{success}</Alert>}
          {error && <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>{error}</Alert>}

          <TextField fullWidth select label="Pay From" value={fromId} onChange={(e) => setFromId(e.target.value)} sx={{ mb: 2 }}>
            {accounts.map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.nickname ?? a.maskedAccountNumber} — {formatCurrency(a.availableBalance)}</MenuItem>
            ))}
          </TextField>

          <TextField fullWidth label="Payee / Biller Name" value={payee} onChange={(e) => setPayee(e.target.value)} sx={{ mb: 2 }} />

          <NumericFormat
            customInput={TextField}
            fullWidth label="Amount" value={amount}
            onValueChange={(v) => setAmount(v.value)}
            thousandSeparator prefix="$" decimalScale={2} fixedDecimalScale
            sx={{ mb: 2 }}
            InputProps={{ startAdornment: <InputAdornment position="start" /> }}
          />

          <TextField fullWidth type="date" label="Payment Date" value={scheduledDate}
            onChange={(e) => setScheduledDate(e.target.value)}
            InputLabelProps={{ shrink: true }} sx={{ mb: 2 }} />

          <TextField fullWidth label="Memo (optional)" value={memo} onChange={(e) => setMemo(e.target.value)} sx={{ mb: 3 }} />

          <Button fullWidth variant="contained" size="large" disabled={!isValid} onClick={() => setConfirmOpen(true)}>
            Review Payment
          </Button>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirmOpen}
        title="Confirm Bill Payment"
        message={`Pay ${formatCurrency(amountCents)} to ${payee} on ${scheduledDate}?`}
        confirmLabel="Pay Now"
        loading={loading}
        onConfirm={handleSubmit}
        onCancel={() => setConfirmOpen(false)}
      />
    </Box>
  );
}
