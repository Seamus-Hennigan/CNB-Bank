export type TransferStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface TransferRequest {
  fromAccountId: string;
  toAccountId: string;
  amount: number; // cents
  memo: string;
  scheduledDate: string | null;
}

export interface BillPayRequest {
  fromAccountId: string;
  payee: string;
  amount: number; // cents
  memo: string;
  scheduledDate: string;
}

export interface DepositRequest {
  toAccountId: string;
  amount: number; // cents
  checkNumber: string;
  memo: string;
}

export interface SendMoneyRequest {
  fromAccountId: string;
  recipientEmail: string;
  recipientName: string;
  amount: number; // cents
  memo: string;
}

export interface TransferResult {
  id: string;
  status: TransferStatus;
  message: string;
  createdAt: string;
}
