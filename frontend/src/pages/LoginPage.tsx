import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Box, Card, CardContent, TextField, Button, Typography,
  Alert, InputAdornment, IconButton, CircularProgress, Divider,
} from '@mui/material';
import cnbLogo from '../assets/logo.png';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import LockIcon from '@mui/icons-material/Lock';
import { useAuth } from '../hooks/useAuth';

export default function LoginPage() {
  const { login, confirmMfa, isAuthenticated, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: string })?.from ?? '/dashboard';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [mfaCode, setMfaCode] = useState('');
  const [mfaRequired, setMfaRequired] = useState(false);

  useEffect(() => {
    if (isAuthenticated) navigate(from, { replace: true });
  }, [isAuthenticated, navigate, from]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    await login(email, password);
  };

  const handleMfa = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    await confirmMfa(mfaCode);
  };

  return (
    <Box minHeight="100vh" display="flex" sx={{ bgcolor: 'background.default' }}>
      {/* Left panel — navy branding */}
      <Box
        sx={{
          display: { xs: 'none', md: 'flex' },
          width: '45%',
          background: 'linear-gradient(160deg, #0A2463 0%, #061840 60%, #0A2463 100%)',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          p: 6,
        }}
      >
        <Box textAlign="center">
          <Box
            sx={{
              width: 104,
              height: 104,
              borderRadius: '50%',
              bgcolor: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              mb: 2,
              mx: 'auto',
            }}
          >
            <img src={cnbLogo} alt="CNB Bank" style={{ width: 72, height: 72, objectFit: 'contain' }} />
          </Box>
          <Typography variant="h1" color="white" gutterBottom>
            CNB Bank
          </Typography>
          <Typography variant="body1" sx={{ color: 'rgba(255,255,255,0.6)', maxWidth: 320, mx: 'auto' }}>
            Trusted banking solutions for over 50 years. Your financial future starts here.
          </Typography>
          <Box mt={6}>
            {[
              'Secure 256-bit encryption',
              'FDIC insured deposits',
              '24/7 fraud monitoring',
            ].map((feat) => (
              <Box key={feat} display="flex" alignItems="center" gap={1.5} mb={1.5}>
                <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#D4AF37', flexShrink: 0 }} />
                <Typography variant="body2" color="rgba(255,255,255,0.7)">{feat}</Typography>
              </Box>
            ))}
          </Box>
        </Box>
      </Box>

      {/* Right panel — login form */}
      <Box flex={1} display="flex" alignItems="center" justifyContent="center" p={3}>
        <Card sx={{ width: '100%', maxWidth: 420, boxShadow: 'none', border: 'none', bgcolor: 'transparent' }}>
          <CardContent sx={{ p: { xs: 2, sm: 4 } }}>
            {/* Mobile logo */}
            <Box display={{ xs: 'flex', md: 'none' }} alignItems="center" justifyContent="center" gap={1.5} mb={4}>
              <img src={cnbLogo} alt="CNB Bank" style={{ width: 36, height: 36, objectFit: 'contain' }} />
              <Typography variant="h2" color="primary.main" fontWeight={700}>CNB Bank</Typography>
            </Box>

            <Box mb={4}>
              <Typography variant="h2" gutterBottom>
                {mfaRequired ? 'Two-Factor Authentication' : 'Welcome back'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {mfaRequired
                  ? 'Enter the 6-digit code from your authenticator app.'
                  : 'Sign in to access your account.'}
              </Typography>
            </Box>

            {process.env.REACT_APP_USE_MOCK_DATA === 'true' && !mfaRequired && (
              <Alert severity="info" sx={{ mb: 3 }}>
                <Typography variant="caption" display="block"><strong>Demo Mode</strong></Typography>
                <Typography variant="caption">
                  Email: jordan.mitchell@email.com<br />Password: Password123!
                </Typography>
              </Alert>
            )}

            {error && (
              <Alert severity="error" sx={{ mb: 3 }} onClose={clearError}>{error}</Alert>
            )}

            {!mfaRequired ? (
              <Box component="form" onSubmit={handleLogin}>
                <TextField
                  fullWidth label="Email Address" type="email"
                  value={email} onChange={(e) => setEmail(e.target.value)}
                  required autoComplete="email" sx={{ mb: 2 }}
                />
                <TextField
                  fullWidth label="Password"
                  type={showPassword ? 'text' : 'password'}
                  value={password} onChange={(e) => setPassword(e.target.value)}
                  required autoComplete="current-password" sx={{ mb: 3 }}
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton onClick={() => setShowPassword(!showPassword)} edge="end" size="small"
                          aria-label={showPassword ? 'Hide password' : 'Show password'}>
                          {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                />
                <Button
                  type="submit" fullWidth variant="contained" size="large"
                  disabled={isLoading || !email || !password}
                  startIcon={isLoading ? <CircularProgress size={18} color="inherit" /> : <LockIcon />}
                >
                  {isLoading ? 'Signing in…' : 'Sign In'}
                </Button>
              </Box>
            ) : (
              <Box component="form" onSubmit={handleMfa}>
                <TextField
                  fullWidth label="Authentication Code" value={mfaCode}
                  onChange={(e) => setMfaCode(e.target.value)}
                  required inputProps={{ maxLength: 6, inputMode: 'numeric' }}
                  sx={{ mb: 3 }} placeholder="000000"
                />
                <Button type="submit" fullWidth variant="contained" size="large"
                  disabled={isLoading || mfaCode.length < 6}>
                  {isLoading ? 'Verifying…' : 'Verify'}
                </Button>
                <Button fullWidth variant="text" onClick={() => setMfaRequired(false)} sx={{ mt: 1 }}>
                  Back to login
                </Button>
              </Box>
            )}

            <Divider sx={{ my: 3 }} />
            <Typography variant="caption" color="text.secondary" textAlign="center" display="block">
              Having trouble signing in? Contact support at 1-800-CNB-BANK
            </Typography>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
}
