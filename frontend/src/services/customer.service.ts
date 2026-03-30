import { Customer } from '../types';
import { isMockMode, mockDelay } from './mock/mock.service';
import { mockCustomer } from './mock/mock-customer';
import { apiGet, apiPut } from './api.service';

export async function getCustomer(): Promise<Customer> {
  if (isMockMode()) return mockDelay(mockCustomer);
  return apiGet<Customer>('/customer/me');
}

export async function updateCustomer(data: Partial<Customer>): Promise<Customer> {
  if (isMockMode()) return mockDelay({ ...mockCustomer, ...data });
  return apiPut<Customer>('/customer/me', data);
}
