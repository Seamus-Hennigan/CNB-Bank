import React from 'react';
import { Typography, TypographyProps } from '@mui/material';

export function formatCurrency(cents: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(cents / 100);
}

interface CurrencyDisplayProps extends TypographyProps {
  cents: number;
  colorCoded?: boolean;
  isDebit?: boolean;
}

export default function CurrencyDisplay({ cents, colorCoded, isDebit, ...props }: CurrencyDisplayProps) {
  const color = colorCoded
    ? isDebit
      ? 'error.main'
      : 'success.main'
    : undefined;

  return (
    <Typography color={color} {...props}>
      {isDebit ? '-' : ''}{formatCurrency(cents)}
    </Typography>
  );
}
