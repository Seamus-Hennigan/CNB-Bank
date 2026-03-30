import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardActionArea, CardContent, Typography, Box, Divider } from '@mui/material';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import SavingsIcon from '@mui/icons-material/Savings';
import { Account } from '../../types';
import { formatCurrency } from '../common/CurrencyDisplay';
import MaskedText from '../common/MaskedText';
import StatusChip from '../common/StatusChip';

interface AccountCardProps {
  account: Account;
}

export default function AccountCard({ account }: AccountCardProps) {
  const navigate = useNavigate();

  return (
    <Card>
      <CardActionArea onClick={() => navigate(`/accounts/${account.id}`)}>
        <CardContent>
          <Box display="flex" alignItems="flex-start" justifyContent="space-between" mb={1.5}>
            <Box display="flex" alignItems="center" gap={1.5}>
              <Box sx={{ width: 40, height: 40, borderRadius: 2, bgcolor: '#EEF1F8', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0A2463' }}>
                {account.type === 'savings' ? <SavingsIcon /> : <AccountBalanceIcon />}
              </Box>
              <Box>
                <Typography variant="subtitle1" fontWeight={600}>
                  {account.nickname ?? `${account.type.charAt(0).toUpperCase()}${account.type.slice(1)} Account`}
                </Typography>
                <MaskedText masked={account.maskedAccountNumber} revealed={account.accountNumber} typographyProps={{ color: 'text.secondary' }} />
              </Box>
            </Box>
            <StatusChip status={account.status} />
          </Box>

          <Divider sx={{ mb: 1.5 }} />

          <Box display="flex" gap={4}>
            <Box>
              <Typography variant="caption" color="text.secondary" textTransform="uppercase" letterSpacing="0.05em">
                Current Balance
              </Typography>
              <Typography variant="h4" color="primary.main">
                {formatCurrency(account.currentBalance)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="caption" color="text.secondary" textTransform="uppercase" letterSpacing="0.05em">
                Available
              </Typography>
              <Typography variant="h4">
                {formatCurrency(account.availableBalance)}
              </Typography>
            </Box>
            {account.interestRate && (
              <Box>
                <Typography variant="caption" color="text.secondary" textTransform="uppercase" letterSpacing="0.05em">
                  APY
                </Typography>
                <Typography variant="h4" sx={{ color: '#D4AF37' }}>
                  {account.interestRate}%
                </Typography>
              </Box>
            )}
          </Box>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
