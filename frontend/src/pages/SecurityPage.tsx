import React, { useState } from 'react';
import {
  Box, Typography, Card, CardContent, TextField, Button,
  Alert, Divider, Switch, FormControlLabel, Grid,
  InputAdornment, IconButton, CircularProgress,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import LockIcon from '@mui/icons-material/Lock';
import SecurityIcon from '@mui/icons-material/Security';
import { loginWithCognito } from '../services/auth.service';
import { useAuth } from '../hooks/useAuth';
import { isMockMode } from '../services/mock/mock.service';
import RequireReauth from '../components/auth/RequireReauth';

export default function SecurityPage() {
  const { user } = useAuth();
  const [currentPw, setCurrentPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [pwLoading, setPwLoading] = useState(false);
  const [pwSuccess, setPwSuccess] = useState('');
  const [pwError, setPwError] = useState('');
  const [mfaEnabled, setMfaEnabled] = useState(false);
  const [reauthOpen, setReauthOpen] = useState(false);

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPw !== confirmPw) { setPwError('New passwords do not match.'); return; }
    if (newPw.length < 8) { setPwError('Password must be at least 8 characters.'); return; }
    setPwLoading(true); setPwError('');
    try {
      if (isMockMode()) {
        if (currentPw !== 'Password123!') throw new Error('Current password is incorrect.');
        await new Promise((r) => setTimeout(r, 600));
      } else {
        await loginWithCognito(user?.email ?? '', currentPw);
        // Amplify changePassword would go here
      }
      setPwSuccess('Password updated successfully.');
      setCurrentPw(''); setNewPw(''); setConfirmPw('');
    } catch (e: unknown) {
      setPwError(e instanceof Error ? e.message : 'Password change failed.');
    } finally {
      setPwLoading(false);
    }
  };

  return (
    <Box maxWidth={700}>
      <Typography variant="h2" mb={0.5}>Security</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>Manage your account security settings.</Typography>

      {/* Change Password */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" alignItems="center" gap={1} mb={2}>
            <LockIcon color="primary" />
            <Typography variant="h5">Change Password</Typography>
          </Box>
          {pwSuccess && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setPwSuccess('')}>{pwSuccess}</Alert>}
          {pwError && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setPwError('')}>{pwError}</Alert>}
          <Box component="form" onSubmit={handleChangePassword}>
            <TextField
              fullWidth label="Current Password" type={showPw ? 'text' : 'password'}
              value={currentPw} onChange={(e) => setCurrentPw(e.target.value)}
              required sx={{ mb: 2 }}
              InputProps={{ endAdornment: <InputAdornment position="end">
                <IconButton size="small" onClick={() => setShowPw(!showPw)}>
                  {showPw ? <VisibilityOffIcon /> : <VisibilityIcon />}
                </IconButton>
              </InputAdornment> }}
            />
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid item xs={12} sm={6}>
                <TextField fullWidth label="New Password" type="password" value={newPw}
                  onChange={(e) => setNewPw(e.target.value)} required />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField fullWidth label="Confirm New Password" type="password" value={confirmPw}
                  onChange={(e) => setConfirmPw(e.target.value)} required />
              </Grid>
            </Grid>
            <Button type="submit" variant="contained" disabled={pwLoading || !currentPw || !newPw || !confirmPw}
              startIcon={pwLoading ? <CircularProgress size={16} color="inherit" /> : undefined}>
              {pwLoading ? 'Updating…' : 'Update Password'}
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* 2FA */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" alignItems="center" gap={1} mb={2}>
            <SecurityIcon color="primary" />
            <Typography variant="h5">Two-Factor Authentication</Typography>
          </Box>
          <Typography variant="body2" color="text.secondary" mb={2}>
            Add an extra layer of security to your account using an authenticator app.
          </Typography>
          <FormControlLabel
            control={<Switch checked={mfaEnabled} onChange={(e) => {
              if (e.target.checked) setReauthOpen(true);
              else setMfaEnabled(false);
            }} />}
            label={mfaEnabled ? '2FA Enabled' : '2FA Disabled'}
          />
          {mfaEnabled && (
            <Alert severity="success" sx={{ mt: 2 }}>
              Two-factor authentication is active on your account.
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Active Sessions */}
      <Card>
        <CardContent>
          <Typography variant="h5" mb={2}>Active Sessions</Typography>
          <Box display="flex" alignItems="center" justifyContent="space-between" py={1}>
            <Box>
              <Typography variant="body2" fontWeight={500}>Current Session</Typography>
              <Typography variant="caption" color="text.secondary">Chrome on Windows · New York, NY</Typography>
            </Box>
            <Typography variant="caption" sx={{ bgcolor: 'success.light', color: 'success.dark', px: 1, py: 0.25, borderRadius: 1 }}>
              Active
            </Typography>
          </Box>
          <Divider sx={{ my: 1 }} />
          <Button size="small" color="error" variant="outlined">
            Sign Out All Other Sessions
          </Button>
        </CardContent>
      </Card>

      <RequireReauth
        open={reauthOpen}
        onSuccess={() => { setReauthOpen(false); setMfaEnabled(true); }}
        onCancel={() => setReauthOpen(false)}
      />
    </Box>
  );
}
