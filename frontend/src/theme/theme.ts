import { createTheme, alpha } from '@mui/material/styles';

const NAVY = '#0A2463';
const LIGHT_NAVY = '#1A3A7A';
const DARK_NAVY = '#061840';
const GOLD = '#D4AF37';
const LIGHT_GOLD = '#E8CC6A';
const DARK_GOLD = '#B8962E';

export const DRAWER_WIDTH = 260;

export const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: NAVY,
      light: LIGHT_NAVY,
      dark: DARK_NAVY,
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: GOLD,
      light: LIGHT_GOLD,
      dark: DARK_GOLD,
      contrastText: NAVY,
    },
    background: {
      default: '#fafafa',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#1A1A2E',
      secondary: '#5A6478',
    },
    success: { main: '#2E7D32' },
    error: { main: '#C62828' },
    warning: { main: '#E65100' },
    info: { main: '#0277BD' },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: { fontWeight: 700, fontSize: '2rem' },
    h2: { fontWeight: 600, fontSize: '1.5rem' },
    h3: { fontWeight: 600, fontSize: '1.25rem' },
    h4: { fontWeight: 600, fontSize: '1.125rem' },
    h5: { fontWeight: 600, fontSize: '1rem' },
    h6: { fontWeight: 600, fontSize: '0.875rem' },
    subtitle1: { fontWeight: 500 },
    subtitle2: { fontWeight: 500, color: '#5A6478' },
    body2: { color: '#5A6478' },
    button: { textTransform: 'none', fontWeight: 600 },
  },
  shape: { borderRadius: 12 },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          textTransform: 'none',
          fontWeight: 600,
          padding: '8px 20px',
        },
        containedPrimary: {
          background: NAVY,
          '&:hover': {
            background: LIGHT_NAVY,
            boxShadow: `0 2px 8px ${alpha(NAVY, 0.25)}`,
          },
        },
        containedSecondary: {
          color: NAVY,
          '&:hover': {
            boxShadow: `0 4px 16px ${alpha(GOLD, 0.3)}`,
          },
        },
        outlinedPrimary: {
          borderColor: NAVY,
          '&:hover': { background: alpha(NAVY, 0.04) },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
          border: '1px solid rgba(0,0,0,0.06)',
        },
      },
    },
    MuiCardContent: {
      styleOverrides: {
        root: { padding: 24, '&:last-child': { paddingBottom: 24 } },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          background: NAVY,
          boxShadow: `0 2px 8px ${alpha(NAVY, 0.2)}`,
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          background: NAVY,
          color: '#FFFFFF',
          borderRight: 'none',
          width: DRAWER_WIDTH,
        },
      },
    },
    MuiListItemButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          margin: '2px 8px',
          width: 'calc(100% - 16px)',
          '&.Mui-selected': {
            background: alpha(GOLD, 0.15),
            color: GOLD,
            '&:hover': { background: alpha(GOLD, 0.2) },
            '& .MuiListItemIcon-root': { color: GOLD },
          },
          '&:hover': { background: alpha('#FFFFFF', 0.08) },
        },
      },
    },
    MuiListItemIcon: {
      styleOverrides: {
        root: { color: alpha('#FFFFFF', 0.7), minWidth: 40 },
      },
    },
    MuiListItemText: {
      styleOverrides: {
        primary: { fontSize: '0.9rem', fontWeight: 500 },
      },
    },
    MuiTextField: {
      defaultProps: { variant: 'outlined', size: 'small' },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          '&:hover .MuiOutlinedInput-notchedOutline': {
            borderColor: NAVY,
          },
          '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
            borderColor: NAVY,
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { fontWeight: 500, borderRadius: 6 },
      },
    },
    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: 12 },
      },
    },
    MuiDivider: {
      styleOverrides: {
        root: { borderColor: alpha(NAVY, 0.08) },
      },
    },
    MuiTableHead: {
      styleOverrides: {
        root: {
          '& .MuiTableCell-head': {
            backgroundColor: '#f5f5f5',
            fontWeight: 600,
            color: '#5A6478',
            fontSize: '0.75rem',
            textTransform: 'uppercase',
            letterSpacing: '0.05em',
          },
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        root: { borderColor: alpha(NAVY, 0.06) },
      },
    },
    MuiAlert: {
      styleOverrides: {
        root: { borderRadius: 8 },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: { borderRadius: 12 },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 600 },
      },
    },
  },
});
