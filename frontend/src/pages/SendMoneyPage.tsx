import React, { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, MenuItem,
  Button, Alert, InputAdornment,
} from '@mui/material';
import { NumericFormat } from 'react-number-format';
import { useAccounts } from '../hooks/useAccounts';
import { submitSendMoney } from '../services/transfer.service';
import ConfirmDialog from '../components/common/ConfirmDialog';
import { formatCurrency } from '../components/common/CurrencyDisplay';

export default function SendMoneyPage() {
  const { accounts } = useAccounts();
  const [fromId, setFromId] = useState('');
  const [recipientEmail, setRecipientEmail] = useState('');
  const [recipientName, setRecipientName] = useState('');
  const [amount, setAmount] = useState('');
  const [memo, setMemo] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const amountCents = Math.round(parseFloat(amount.replace(/,/g, '') || '0') * 100);
  const isValid = fromId && recipientEmail && recipientName && amountCents > 0;

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await submitSendMoney({ fromAccountId: fromId, recipientEmail, recipientName, amount: amountCents, memo });
      setSuccess(res.message);
      setConfirmOpen(false);
      setRecipientEmail(''); setRecipientName(''); setAmount(''); setMemo('');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Payment failed.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box maxWidth={600}>
      <Typography variant="h2" mb={0.5}>Send Money</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>Send money instantly to anyone.</Typography>

      <Card>
        <CardContent>
          {success && <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess('')}>{success}</Alert>}
          {error && <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>{error}</Alert>}

          <TextField fullWidth select label="From Account" value={fromId} onChange={(e) => setFromId(e.target.value)} sx={{ mb: 2 }}>
            {accounts.map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.nickname ?? a.maskedAccountNumber} — {formatCurrency(a.availableBalance)}</MenuItem>
            ))}
          </TextField>

          <TextField fullWidth label="Recipient Name" value={recipientName} onChange={(e) => setRecipientName(e.target.value)} sx={{ mb: 2 }} />
          <TextField fullWidth label="Recipient Email" type="email" value={recipientEmail} onChange={(e) => setRecipientEmail(e.target.value)} sx={{ mb: 2 }} />

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
            Review Payment
          </Button>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirmOpen}
        title="Confirm Payment"
        message={`Send ${formatCurrency(amountCents)} to ${recipientName} (${recipientEmail})?`}
        confirmLabel="Send"
        loading={loading}
        onConfirm={handleSubmit}
        onCancel={() => setConfirmOpen(false)}
      />
    </Box>
  );
}
