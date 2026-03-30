import React, { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem,
  Button, Alert, InputAdornment,
} from '@mui/material';
import { NumericFormat } from 'react-number-format';
import { useAccounts } from '../hooks/useAccounts';
import { submitDeposit } from '../services/transfer.service';
import ConfirmDialog from '../components/common/ConfirmDialog';
import { formatCurrency } from '../components/common/CurrencyDisplay';

export default function DepositPage() {
  const { accounts } = useAccounts();
  const [toId, setToId] = useState('');
  const [amount, setAmount] = useState('');
  const [checkNumber, setCheckNumber] = useState('');
  const [memo, setMemo] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const amountCents = Math.round(parseFloat(amount.replace(/,/g, '') || '0') * 100);
  const isValid = toId && amountCents > 0 && checkNumber;

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await submitDeposit({ toAccountId: toId, amount: amountCents, checkNumber, memo });
      setSuccess(res.message);
      setConfirmOpen(false);
      setAmount(''); setCheckNumber(''); setMemo('');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Deposit failed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box maxWidth={600}>
      <Typography variant="h2" mb={0.5}>Deposit a Check</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>Submit a mobile check deposit.</Typography>

      <Card>
        <CardContent>
          {success && <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess('')}>{success}</Alert>}
          {error && <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>{error}</Alert>}

          <TextField fullWidth select label="Deposit To" value={toId} onChange={(e) => setToId(e.target.value)} sx={{ mb: 2 }}>
            {accounts.map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.nickname ?? a.maskedAccountNumber}</MenuItem>
            ))}
          </TextField>

          <NumericFormat
            customInput={TextField}
            fullWidth label="Check Amount" value={amount}
            onValueChange={(v) => setAmount(v.value)}
            thousandSeparator prefix="$" decimalScale={2} fixedDecimalScale
            sx={{ mb: 2 }}
            InputProps={{ startAdornment: <InputAdornment position="start" /> }}
          />

          <TextField fullWidth label="Check Number" value={checkNumber} onChange={(e) => setCheckNumber(e.target.value)} sx={{ mb: 2 }} />
          <TextField fullWidth label="Memo (optional)" value={memo} onChange={(e) => setMemo(e.target.value)} sx={{ mb: 3 }} />

          <Button fullWidth variant="contained" size="large" disabled={!isValid} onClick={() => setConfirmOpen(true)}>
            Submit Deposit
          </Button>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirmOpen}
        title="Confirm Deposit"
        message={`Deposit ${formatCurrency(amountCents)} (check #${checkNumber})?`}
        confirmLabel="Deposit"
        loading={loading}
        onConfirm={handleSubmit}
        onCancel={() => setConfirmOpen(false)}
      />
    </Box>
  );
}
