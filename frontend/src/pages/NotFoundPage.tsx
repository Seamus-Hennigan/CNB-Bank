import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Typography, Button } from '@mui/material';
import HomeIcon from '@mui/icons-material/Home';

export default function NotFoundPage() {
  const navigate = useNavigate();

  return (
    <Box
      display="flex"
      flexDirection="column"
      alignItems="center"
      justifyContent="center"
      minHeight="60vh"
      textAlign="center"
      gap={2}
    >
      <Typography variant="h1" sx={{ fontSize: '5rem', fontWeight: 700, color: 'primary.main', lineHeight: 1 }}>
        404
      </Typography>
      <Typography variant="h3" color="text.primary">
        Page Not Found
      </Typography>
      <Typography variant="body1" color="text.secondary" maxWidth={400}>
        The page you're looking for doesn't exist or has been moved.
      </Typography>
      <Button
        variant="contained"
        startIcon={<HomeIcon />}
        onClick={() => navigate('/dashboard')}
        sx={{ mt: 1 }}
      >
        Back to Dashboard
      </Button>
    </Box>
  );
}
