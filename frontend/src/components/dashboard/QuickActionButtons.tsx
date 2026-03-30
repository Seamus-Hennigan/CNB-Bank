import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Grid, Card, CardActionArea, CardContent, Typography, Box } from '@mui/material';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import ReceiptIcon from '@mui/icons-material/Receipt';
import AddCardIcon from '@mui/icons-material/AddCard';
import SendIcon from '@mui/icons-material/Send';

const actions = [
  { label: 'Transfer Money', path: '/transfer',   icon: <SwapHorizIcon fontSize="small" />, color: '#0A2463', bg: '#EEF1F8' },
  { label: 'Pay a Bill',     path: '/bill-pay',   icon: <ReceiptIcon fontSize="small" />,   color: '#2E7D32', bg: '#EDF7EE' },
  { label: 'Deposit Check',  path: '/deposit',    icon: <AddCardIcon fontSize="small" />,   color: '#0277BD', bg: '#E3F2FB' },
  { label: 'Send Money',     path: '/send-money', icon: <SendIcon fontSize="small" />,      color: '#6A1B9A', bg: '#F3E8FB' },
];

export default function QuickActionButtons() {
  const navigate = useNavigate();

  return (
    <Grid container spacing={2} mb={3}>
      {actions.map((action) => (
        <Grid item xs={6} sm={3} key={action.path}>
          <Card sx={{ height: '100%', '&:hover': { boxShadow: '0 2px 12px rgba(0,0,0,0.12)' }, transition: 'box-shadow 0.15s' }}>
            <CardActionArea onClick={() => navigate(action.path)} sx={{ height: '100%' }}>
              <CardContent sx={{ textAlign: 'center', py: 2.5 }}>
                <Box
                  sx={{
                    width: 44,
                    height: 44,
                    borderRadius: '50%',
                    bgcolor: action.bg,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    mx: 'auto',
                    mb: 1.5,
                    color: action.color,
                  }}
                >
                  {action.icon}
                </Box>
                <Typography variant="body2" fontWeight={600} color="text.primary" fontSize="0.8rem">
                  {action.label}
                </Typography>
              </CardContent>
            </CardActionArea>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}
