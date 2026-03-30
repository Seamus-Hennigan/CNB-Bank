import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Skeleton,
  Divider,
} from '@mui/material';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import { Account } from '../../types';
import { formatCurrency } from '../common/CurrencyDisplay';
import MaskedText from '../common/MaskedText';
import AccountBadge from '../accounts/AccountBadge';
import StatusChip from '../common/StatusChip';

interface AccountOverviewCardProps {
  account: Account | null;
  loading?: boolean;
}

export default function AccountOverviewCard({ account, loading }: AccountOverviewCardProps) {
  const navigate = useNavigate();

  if (loading || !account) {
    return (
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Skeleton variant="text" width={120} />
          <Skeleton variant="text" width={200} height={50} />
          <Skeleton variant="text" width={160} />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card sx={{ mb: 3, bgcolor: '#0A2463', color: 'white' }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Box display="flex" alignItems="center" gap={1}>
            <AccountBadge type={account.type} />
            <StatusChip status={account.status} />
          </Box>
          <MaskedText
            masked={account.maskedAccountNumber}
            revealed={account.accountNumber}
            typographyProps={{ color: 'rgba(255,255,255,0.6)', fontSize: '0.85rem' }}
          />
        </Box>

        <Typography
          variant="body2"
          sx={{ color: 'rgba(255,255,255,0.6)', mb: 0.5, textTransform: 'uppercase', letterSpacing: '0.05em', fontSize: '0.7rem' }}
        >
          Current Balance
        </Typography>

        <Typography
          variant="h1"
          sx={{ color: 'white', fontWeight: 700, fontSize: { xs: '2rem', sm: '2.5rem' }, mb: 2 }}
        >
          {formatCurrency(account.currentBalance)}
        </Typography>

        <Divider sx={{ borderColor: 'rgba(255,255,255,0.12)', mb: 2 }} />

        <Box display="flex" gap={4} flexWrap="wrap" alignItems="center" justifyContent="space-between">
          <Box display="flex" gap={4} flexWrap="wrap">
            <Box>
              <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Available
              </Typography>
              <Typography variant="h5" color="white" fontWeight={600}>
                {formatCurrency(account.availableBalance)}
              </Typography>
            </Box>
            {account.interestRate && (
              <Box>
                <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  APY Rate
                </Typography>
                <Typography variant="h5" sx={{ color: '#D4AF37', fontWeight: 600 }}>
                  {account.interestRate}%
                </Typography>
              </Box>
            )}
          </Box>
          <Button
            size="small"
            endIcon={<ArrowForwardIcon />}
            onClick={() => navigate(`/accounts/${account.id}`)}
            sx={{ color: 'rgba(255,255,255,0.7)', '&:hover': { color: '#D4AF37' } }}
          >
            View Details
          </Button>
        </Box>
      </CardContent>
    </Card>
  );
}
