import React, { useState, useEffect } from 'react';
import {
  Box, Typography, Card, CardContent, List, ListItem,
  ListItemText, ListItemIcon, Divider, Switch, FormControlLabel,
  Button, Alert, Grid, TextField, InputAdornment, CircularProgress,
} from '@mui/material';
import NotificationsIcon from '@mui/icons-material/Notifications';
import InfoIcon from '@mui/icons-material/Info';
import WarningIcon from '@mui/icons-material/Warning';
import ErrorIcon from '@mui/icons-material/Error';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { useNotifications } from '../hooks/useNotifications';
import { getNotificationPreferences, updateNotificationPreferences } from '../services/notification.service';
import { NotificationPreferences, NotificationSeverity } from '../types';
import { NumericFormat } from 'react-number-format';
import { formatDistanceToNow } from 'date-fns';

const severityIcon: Record<NotificationSeverity, React.ReactNode> = {
  info:    <InfoIcon color="info" fontSize="small" />,
  warning: <WarningIcon color="warning" fontSize="small" />,
  error:   <ErrorIcon color="error" fontSize="small" />,
  success: <CheckCircleIcon color="success" fontSize="small" />,
};

export default function NotificationsPage() {
  const { notifications, loading, markRead, unreadCount } = useNotifications();
  const [prefs, setPrefs] = useState<NotificationPreferences | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState('');

  useEffect(() => {
    getNotificationPreferences().then(setPrefs);
  }, []);

  const handleSavePrefs = async () => {
    if (!prefs) return;
    setSaving(true);
    try {
      const updated = await updateNotificationPreferences(prefs);
      setPrefs(updated);
      setSaveSuccess('Preferences saved.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Box>
      <Typography variant="h2" mb={0.5}>Notifications</Typography>
      <Typography variant="body2" color="text.secondary" mb={3}>
        {unreadCount > 0 ? `${unreadCount} unread notification${unreadCount > 1 ? 's' : ''}` : 'All caught up!'}
      </Typography>

      <Grid container spacing={3}>
        {/* Notification list */}
        <Grid item xs={12} md={7}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
                <Typography variant="h5">Recent Alerts</Typography>
                {unreadCount > 0 && (
                  <Button size="small" onClick={() => notifications.filter((n) => !n.read).forEach((n) => markRead(n.id))}>
                    Mark all read
                  </Button>
                )}
              </Box>
              {loading ? (
                <Box textAlign="center" py={4}><CircularProgress size={24} /></Box>
              ) : (
                <List disablePadding>
                  {notifications.map((n, idx) => (
                    <React.Fragment key={n.id}>
                      <ListItem
                        disablePadding
                        sx={{ py: 1.5, opacity: n.read ? 0.6 : 1, cursor: n.read ? 'default' : 'pointer' }}
                        onClick={() => !n.read && markRead(n.id)}
                      >
                        <ListItemIcon sx={{ minWidth: 36 }}>{severityIcon[n.severity]}</ListItemIcon>
                        <ListItemText
                          primary={
                            <Box display="flex" alignItems="center" gap={1}>
                              <Typography variant="body2" fontWeight={n.read ? 400 : 600}>{n.title}</Typography>
                              {!n.read && <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: 'primary.main' }} />}
                            </Box>
                          }
                          secondary={
                            <>
                              <Typography variant="caption" display="block">{n.message}</Typography>
                              <Typography variant="caption" color="text.disabled">
                                {formatDistanceToNow(new Date(n.createdAt), { addSuffix: true })}
                              </Typography>
                            </>
                          }
                        />
                      </ListItem>
                      {idx < notifications.length - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Preferences */}
        <Grid item xs={12} md={5}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <NotificationsIcon color="primary" fontSize="small" />
                <Typography variant="h5">Preferences</Typography>
              </Box>

              {saveSuccess && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSaveSuccess('')}>{saveSuccess}</Alert>}

              {prefs && (
                <>
                  <NumericFormat
                    customInput={TextField}
                    fullWidth label="Low Balance Alert Threshold"
                    value={prefs.lowBalanceThreshold / 100}
                    onValueChange={(v) => setPrefs({ ...prefs, lowBalanceThreshold: Math.round((parseFloat(v.value) || 0) * 100) })}
                    thousandSeparator prefix="$" decimalScale={0}
                    sx={{ mb: 2 }}
                    InputProps={{ startAdornment: <InputAdornment position="start" /> }}
                  />
                  <NumericFormat
                    customInput={TextField}
                    fullWidth label="Large Transaction Alert Threshold"
                    value={prefs.largeTransactionThreshold / 100}
                    onValueChange={(v) => setPrefs({ ...prefs, largeTransactionThreshold: Math.round((parseFloat(v.value) || 0) * 100) })}
                    thousandSeparator prefix="$" decimalScale={0}
                    sx={{ mb: 2 }}
                    InputProps={{ startAdornment: <InputAdornment position="start" /> }}
                  />
                  <Divider sx={{ mb: 2 }} />
                  <FormControlLabel
                    control={<Switch checked={prefs.emailAlerts} onChange={(e) => setPrefs({ ...prefs, emailAlerts: e.target.checked })} />}
                    label="Email Alerts" sx={{ display: 'flex', mb: 1 }}
                  />
                  <FormControlLabel
                    control={<Switch checked={prefs.smsAlerts} onChange={(e) => setPrefs({ ...prefs, smsAlerts: e.target.checked })} />}
                    label="SMS Alerts" sx={{ display: 'flex', mb: 1 }}
                  />
                  <FormControlLabel
                    control={<Switch checked={prefs.loginAlerts} onChange={(e) => setPrefs({ ...prefs, loginAlerts: e.target.checked })} />}
                    label="Login Alerts" sx={{ display: 'flex', mb: 1 }}
                  />
                  <FormControlLabel
                    control={<Switch checked={prefs.marketingEmails} onChange={(e) => setPrefs({ ...prefs, marketingEmails: e.target.checked })} />}
                    label="Marketing Emails" sx={{ display: 'flex', mb: 2 }}
                  />
                  <Button fullWidth variant="contained" onClick={handleSavePrefs} disabled={saving}
                    startIcon={saving ? <CircularProgress size={16} color="inherit" /> : undefined}>
                    {saving ? 'Saving…' : 'Save Preferences'}
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
