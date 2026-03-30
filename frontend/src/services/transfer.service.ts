import { TransferRequest, BillPayRequest, DepositRequest, SendMoneyRequest, TransferResult } from '../types';
import { isMockMode, mockDelay } from './mock/mock.service';
import { apiPost } from './api.service';

const mockResult = (label: string): TransferResult => ({
  id: `mock-${Date.now()}`,
  status: 'completed',
  message: `${label} submitted successfully.`,
  createdAt: new Date().toISOString(),
});

export async function submitTransfer(req: TransferRequest): Promise<TransferResult> {
  if (isMockMode()) return mockDelay(mockResult('Transfer'), 800);
  return apiPost<TransferResult>('/transfers', req);
}

export async function submitBillPay(req: BillPayRequest): Promise<TransferResult> {
  if (isMockMode()) return mockDelay(mockResult('Bill payment'), 800);
  return apiPost<TransferResult>('/bill-pay', req);
}

export async function submitDeposit(req: DepositRequest): Promise<TransferResult> {
  if (isMockMode()) return mockDelay(mockResult('Deposit'), 800);
  return apiPost<TransferResult>('/deposits', req);
}

export async function submitSendMoney(req: SendMoneyRequest): Promise<TransferResult> {
  if (isMockMode()) return mockDelay(mockResult('Payment'), 800);
  return apiPost<TransferResult>('/send-money', req);
}
