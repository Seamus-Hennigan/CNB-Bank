import React from 'react';
import { Alert, AlertTitle, Box } from '@mui/material';

interface ErrorAlertProps {
  message: string;
  title?: string;
  onClose?: () => void;
}

export default function ErrorAlert({ message, title, onClose }: ErrorAlertProps) {
  return (
    <Box mb={2}>
      <Alert severity="error" onClose={onClose}>
        {title && <AlertTitle>{title}</AlertTitle>}
        {message}
      </Alert>
    </Box>
  );
}
