import { Account } from '../types';
import { isMockMode, mockDelay } from './mock/mock.service';
import { mockAccounts } from './mock/mock-accounts';
import { apiGet } from './api.service';

export async function getAccounts(): Promise<Account[]> {
  if (isMockMode()) return mockDelay(mockAccounts);
  return apiGet<Account[]>('/accounts');
}

export async function getAccountById(id: string): Promise<Account | null> {
  if (isMockMode()) {
    const account = mockAccounts.find((a) => a.id === id) ?? null;
    return mockDelay(account);
  }
  return apiGet<Account>(`/accounts/${id}`);
}
