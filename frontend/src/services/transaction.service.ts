import { Transaction } from '../types';
import { isMockMode, mockDelay } from './mock/mock.service';
import { mockTransactions } from './mock/mock-transactions';
import { apiGet } from './api.service';

export async function getTransactions(accountId: string): Promise<Transaction[]> {
  if (isMockMode()) {
    const txns = mockTransactions.filter((t) => t.accountId === accountId);
    return mockDelay(txns);
  }
  return apiGet<Transaction[]>(`/accounts/${accountId}/transactions`);
}

export async function getRecentTransactions(
  accountId: string,
  limit = 8
): Promise<Transaction[]> {
  if (isMockMode()) {
    const txns = mockTransactions
      .filter((t) => t.accountId === accountId)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, limit);
    return mockDelay(txns);
  }
  return apiGet<Transaction[]>(`/accounts/${accountId}/transactions?limit=${limit}`);
}

export async function getAllTransactions(): Promise<Transaction[]> {
  if (isMockMode()) return mockDelay(mockTransactions);
  return apiGet<Transaction[]>('/transactions');
}
