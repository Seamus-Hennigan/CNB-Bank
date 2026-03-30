export type NotificationType =
  | 'low_balance'
  | 'large_transaction'
  | 'payment_reminder'
  | 'login_alert'
  | 'failed_transaction'
  | 'general';

export type NotificationSeverity = 'info' | 'warning' | 'error' | 'success';

export interface Notification {
  id: string;
  type: NotificationType;
  severity: NotificationSeverity;
  title: string;
  message: string;
  read: boolean;
  createdAt: string;
  accountId: string | null;
}

export interface NotificationPreferences {
  lowBalanceThreshold: number; // cents
  largeTransactionThreshold: number; // cents
  emailAlerts: boolean;
  smsAlerts: boolean;
  loginAlerts: boolean;
  marketingEmails: boolean;
}
