import React from 'react';
import { Chip } from '@mui/material';
import { AccountType } from '../../types';

const labels: Record<AccountType, string> = {
  checking:     'Checking',
  savings:      'Savings',
  money_market: 'Money Market',
  cd:           'CD',
};

interface AccountBadgeProps {
  type: AccountType;
}

export default function AccountBadge({ type }: AccountBadgeProps) {
  return (
    <Chip
      label={labels[type]}
      size="small"
      sx={{
        bgcolor: 'rgba(255,255,255,0.15)',
        color: 'white',
        fontWeight: 600,
        fontSize: '0.7rem',
      }}
    />
  );
}
