import { Account } from '../../types';

export const mockAccounts: Account[] = [
  {
    id: 'acc-001',
    accountNumber: '7823004521',
    maskedAccountNumber: '****4521',
    routingNumber: '021000021',
    maskedRoutingNumber: '*****0021',
    type: 'checking',
    status: 'active',
    nickname: 'Primary Checking',
    openedDate: '2019-03-15',
    currentBalance: 427650,    // $4,276.50
    availableBalance: 402650,  // $4,026.50 (pending hold)
    interestRate: null,
    linkedAccounts: ['acc-002'],
  },
  {
    id: 'acc-002',
    accountNumber: '7823007803',
    maskedAccountNumber: '****7803',
    routingNumber: '021000021',
    maskedRoutingNumber: '*****0021',
    type: 'savings',
    status: 'active',
    nickname: 'High-Yield Savings',
    openedDate: '2019-03-15',
    currentBalance: 1534200,   // $15,342.00
    availableBalance: 1534200,
    interestRate: 4.75,
    linkedAccounts: ['acc-001'],
  },
];
