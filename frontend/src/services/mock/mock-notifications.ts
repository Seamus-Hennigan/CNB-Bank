import { Notification } from '../../types';
import { subDays, formatISO } from 'date-fns';

const d = (daysAgo: number) => formatISO(subDays(new Date(), daysAgo));

export const mockNotifications: Notification[] = [
  {
    id: 'notif-001',
    type: 'low_balance',
    severity: 'warning',
    title: 'Low Balance Alert',
    message: 'Your Checking account ****4521 balance has dropped below $500.',
    read: false,
    createdAt: d(0),
    accountId: 'acc-001',
  },
  {
    id: 'notif-002',
    type: 'large_transaction',
    severity: 'info',
    title: 'Large Transaction Detected',
    message: 'A transaction of $500.00 was made on your account ****4521 at Amazon.',
    read: false,
    createdAt: d(1),
    accountId: 'acc-001',
  },
  {
    id: 'notif-003',
    type: 'payment_reminder',
    severity: 'info',
    title: 'Bill Payment Due Soon',
    message: 'Your Verizon Wireless bill of $120.00 is due in 3 days.',
    read: true,
    createdAt: d(2),
    accountId: 'acc-001',
  },
  {
    id: 'notif-004',
    type: 'login_alert',
    severity: 'warning',
    title: 'New Login Detected',
    message: 'A new login was detected from New York, NY on a Chrome browser.',
    read: true,
    createdAt: d(3),
    accountId: null,
  },
  {
    id: 'notif-005',
    type: 'failed_transaction',
    severity: 'error',
    title: 'Payment Failed',
    message: 'Your auto-pay for Equinox gym membership of $150.00 failed due to insufficient funds.',
    read: true,
    createdAt: d(17),
    accountId: 'acc-001',
  },
];

export const mockNotificationPreferences = {
  lowBalanceThreshold: 50000,    // $500
  largeTransactionThreshold: 50000, // $500
  emailAlerts: true,
  smsAlerts: false,
  loginAlerts: true,
  marketingEmails: false,
};
