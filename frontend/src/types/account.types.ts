export type AccountType = 'checking' | 'savings' | 'money_market' | 'cd';
export type AccountStatus = 'active' | 'frozen' | 'closed' | 'pending';

export interface Account {
  id: string;
  accountNumber: string;
  maskedAccountNumber: string;
  routingNumber: string;
  maskedRoutingNumber: string;
  type: AccountType;
  status: AccountStatus;
  nickname: string | null;
  openedDate: string;
  currentBalance: number;   // cents
  availableBalance: number; // cents
  interestRate: number | null;
  linkedAccounts: string[];
}
