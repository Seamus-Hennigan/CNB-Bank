import React, { useState } from 'react';
import { Box, Typography, TypographyProps, IconButton, Tooltip } from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';

interface MaskedTextProps {
  masked: string;
  revealed: string;
  typographyProps?: TypographyProps;
}

export default function MaskedText({ masked, revealed, typographyProps }: MaskedTextProps) {
  const [show, setShow] = useState(false);

  return (
    <Box display="flex" alignItems="center" gap={0.5}>
      <Typography variant="body2" fontFamily="monospace" {...typographyProps}>
        {show ? revealed : masked}
      </Typography>
      <Tooltip title={show ? 'Hide' : 'Show'}>
        <IconButton size="small" onClick={() => setShow(!show)} sx={{ p: 0.25 }}>
          {show
            ? <VisibilityOffIcon sx={{ fontSize: 14, ...typographyProps?.sx }} />
            : <VisibilityIcon sx={{ fontSize: 14, ...typographyProps?.sx }} />
          }
        </IconButton>
      </Tooltip>
    </Box>
  );
}
