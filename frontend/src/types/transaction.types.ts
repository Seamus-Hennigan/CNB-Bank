export type TransactionType =
  | 'debit'
  | 'credit'
  | 'transfer_in'
  | 'transfer_out'
  | 'bill_payment'
  | 'deposit'
  | 'fee'
  | 'interest'
  | 'atm_withdrawal'
  | 'p2p_sent'
  | 'p2p_received';

export type TransactionStatus = 'completed' | 'pending' | 'failed' | 'reversed';

export interface Transaction {
  id: string;
  accountId: string;
  type: TransactionType;
  status: TransactionStatus;
  amount: number;         // cents, always positive
  runningBalance: number; // cents
  description: string;
  merchantName: string | null;
  date: string;           // ISO 8601
  postedDate: string | null;
  referenceNumber: string;
}

export interface TransactionFilters {
  search: string;
  startDate: string;
  endDate: string;
  type: TransactionType | '';
  status: TransactionStatus | '';
  accountId: string;
}
