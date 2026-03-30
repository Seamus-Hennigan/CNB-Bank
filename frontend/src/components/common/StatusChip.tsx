import React from 'react';
import { Chip } from '@mui/material';
import { AccountStatus, TransactionStatus } from '../../types';

type Status = AccountStatus | TransactionStatus;

const statusConfig: Record<Status, { label: string; color: 'success' | 'error' | 'warning' | 'default' | 'info' }> = {
  active:    { label: 'Active',    color: 'success' },
  frozen:    { label: 'Frozen',    color: 'warning' },
  closed:    { label: 'Closed',    color: 'error'   },
  pending:   { label: 'Pending',   color: 'warning' },
  completed: { label: 'Completed', color: 'success' },
  failed:    { label: 'Failed',    color: 'error'   },
  reversed:  { label: 'Reversed',  color: 'default' },
};

interface StatusChipProps {
  status: Status;
  size?: 'small' | 'medium';
}

export default function StatusChip({ status, size = 'small' }: StatusChipProps) {
  const cfg = statusConfig[status] ?? { label: status, color: 'default' as const };
  return <Chip label={cfg.label} color={cfg.color} size={size} />;
}
