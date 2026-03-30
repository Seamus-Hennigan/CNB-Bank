import React, { useEffect, useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, Grid,
  Button, Alert, Divider, CircularProgress,
} from '@mui/material';
import { Customer } from '../types';
import { getCustomer, updateCustomer } from '../services/customer.service';
import RequireReauth from '../components/auth/RequireReauth';

export default function ProfilePage() {
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [reauthOpen, setReauthOpen] = useState(false);
  const [pendingUpdate, setPendingUpdate] = useState<Partial<Customer> | null>(null);

  const [form, setForm] = useState({
    given_name: '', family_name: '', phone: '', preferredName: '',
    street: '', city: '', state: '', zip: '',
  });

  useEffect(() => {
    getCustomer().then((c) => {
      setCustomer(c);
      setForm({
        given_name: c.given_name,
        family_name: c.family_name,
        phone: c.phone,
        preferredName: c.preferredName ?? '',
        street: c.address.street,
        city: c.address.city,
        state: c.address.state,
        zip: c.address.zip,
      });
    }).finally(() => setLoading(false));
  }, []);

  const handleSave = () => {
    const update: Partial<Customer> = {
      given_name: form.given_name,
      family_name: form.family_name,
      phone: form.phone,
      preferredName: form.preferredName || null,
      address: { street: form.street, city: form.city, state: form.state, zip: form.zip, country: 'US' },
    };
    setPendingUpdate(update);
    setReauthOpen(true);
  };

  const handleReauthSuccess = async () => {
    if (!pendingUpdate) return;
    setReauthOpen(false);
    setSaving(true);
    setError('');
    try {
      const updated = await updateCustomer(pendingUpdate);
      setCustomer(updated);
      setSuccess('Profile updated successfully.');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Update failed.');
    } finally {
      setSaving(false);
      setPendingUpdate(null);
    }
  };

  const set = (key: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm({ ...form, [key]: e.target.value });

  if (loading) return <Box py={6} textAlign="center"><CircularProgress /></Box>;

  return (
    <Box maxWidth={700}>
      <Typography variant="h2" mb={0.5}>Profile</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>
        Manage your personal information.
      </Typography>

      <Card>
        <CardContent>
          {success && <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccess('')}>{success}</Alert>}
          {error && <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError('')}>{error}</Alert>}

          <Typography variant="h5" mb={2}>Personal Information</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="First Name" value={form.given_name} onChange={set('given_name')} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Last Name" value={form.family_name} onChange={set('family_name')} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Preferred Name (optional)" value={form.preferredName} onChange={set('preferredName')} />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField fullWidth label="Phone Number" value={form.phone} onChange={set('phone')} />
            </Grid>
            <Grid item xs={12}>
              <TextField fullWidth label="Email Address" value={customer?.email ?? ''} disabled
                helperText="Contact support to change your email address." />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          <Typography variant="h5" mb={2}>Address</Typography>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField fullWidth label="Street Address" value={form.street} onChange={set('street')} />
            </Grid>
            <Grid item xs={12} sm={5}>
              <TextField fullWidth label="City" value={form.city} onChange={set('city')} />
            </Grid>
            <Grid item xs={6} sm={3}>
              <TextField fullWidth label="State" value={form.state} onChange={set('state')} inputProps={{ maxLength: 2 }} />
            </Grid>
            <Grid item xs={6} sm={4}>
              <TextField fullWidth label="ZIP Code" value={form.zip} onChange={set('zip')} inputProps={{ maxLength: 10 }} />
            </Grid>
          </Grid>

          <Box mt={3} display="flex" justifyContent="flex-end">
            <Button variant="contained" onClick={handleSave} disabled={saving}
              startIcon={saving ? <CircularProgress size={16} color="inherit" /> : undefined}>
              {saving ? 'Saving…' : 'Save Changes'}
            </Button>
          </Box>
        </CardContent>
      </Card>

      <RequireReauth open={reauthOpen} onSuccess={handleReauthSuccess} onCancel={() => setReauthOpen(false)} />
    </Box>
  );
}
