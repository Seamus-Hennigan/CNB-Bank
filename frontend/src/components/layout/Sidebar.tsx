import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Drawer,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Divider,
  Typography,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import SwapHorizIcon from '@mui/icons-material/SwapHoriz';
import ReceiptIcon from '@mui/icons-material/Receipt';
import AddCardIcon from '@mui/icons-material/AddCard';
import SendIcon from '@mui/icons-material/Send';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';
import PersonIcon from '@mui/icons-material/Person';
import SecurityIcon from '@mui/icons-material/Security';
import NotificationsIcon from '@mui/icons-material/Notifications';
import cnbLogo from '../../assets/logo.png';

interface NavItem {
  label: string;
  path: string;
  icon: React.ReactNode;
}

const navGroups: { title: string; items: NavItem[] }[] = [
  {
    title: 'Overview',
    items: [
      { label: 'Dashboard',    path: '/dashboard',    icon: <DashboardIcon /> },
      { label: 'Transactions', path: '/transactions', icon: <ReceiptLongIcon /> },
      { label: 'Accounts',     path: '/accounts',     icon: <AccountBalanceIcon /> },
    ],
  },
  {
    title: 'Quick Actions',
    items: [
      { label: 'Transfer Money',  path: '/transfer',   icon: <SwapHorizIcon /> },
      { label: 'Pay a Bill',      path: '/bill-pay',   icon: <ReceiptIcon /> },
      { label: 'Deposit a Check', path: '/deposit',    icon: <AddCardIcon /> },
      { label: 'Send Money',      path: '/send-money', icon: <SendIcon /> },
    ],
  },
  {
    title: 'Settings',
    items: [
      { label: 'Profile',       path: '/profile',       icon: <PersonIcon /> },
      { label: 'Security',      path: '/security',      icon: <SecurityIcon /> },
      { label: 'Notifications', path: '/notifications', icon: <NotificationsIcon /> },
    ],
  },
];

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const handleNav = (path: string) => {
    navigate(path);
    if (isMobile) onClose();
  };

  const isActive = (path: string) => location.pathname === path;

  const drawerContent = (
    <Box height="100%" display="flex" flexDirection="column">
      {/* Logo */}
      <Box px={3} py={3} display="flex" alignItems="center" gap={1.5}>
        <Box
          sx={{
            width: 44,
            height: 44,
            borderRadius: '50%',
            bgcolor: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          <img src={cnbLogo} alt="CNB Bank" style={{ width: 30, height: 30, objectFit: 'contain' }} />
        </Box>
        <Box>
          <Typography variant="h5" color="white" fontWeight={700} lineHeight={1.1}>
            CNB Bank
          </Typography>
          <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.5)' }}>
            Member FDIC
          </Typography>
        </Box>
      </Box>

      <Divider sx={{ borderColor: 'rgba(255,255,255,0.1)' }} />

      {/* Nav groups */}
      <Box flex={1} py={1} sx={{ overflowY: 'auto' }}>
        {navGroups.map((group) => (
          <Box key={group.title} mt={1}>
            <Typography
              variant="caption"
              sx={{
                color: 'rgba(255,255,255,0.4)',
                px: 2,
                py: 0.5,
                display: 'block',
                textTransform: 'uppercase',
                letterSpacing: '0.08em',
                fontWeight: 600,
              }}
            >
              {group.title}
            </Typography>
            <List dense disablePadding>
              {group.items.map((item) => (
                <ListItemButton
                  key={item.path}
                  selected={isActive(item.path)}
                  onClick={() => handleNav(item.path)}
                  sx={{ color: isActive(item.path) ? 'inherit' : 'rgba(255,255,255,0.8)' }}
                >
                  <ListItemIcon>{item.icon}</ListItemIcon>
                  <ListItemText primary={item.label} />
                </ListItemButton>
              ))}
            </List>
          </Box>
        ))}
      </Box>

      <Divider sx={{ borderColor: 'rgba(255,255,255,0.1)' }} />
      <Box px={3} py={2}>
        <Typography variant="caption" sx={{ color: 'rgba(255,255,255,0.3)' }}>
          © {new Date().getFullYear()} CNB Bank N.A.
        </Typography>
      </Box>
    </Box>
  );

  return (
    <Drawer
      variant={isMobile ? 'temporary' : 'permanent'}
      open={isMobile ? open : true}
      onClose={onClose}
      ModalProps={{ keepMounted: true }}
    >
      {drawerContent}
    </Drawer>
  );
}
