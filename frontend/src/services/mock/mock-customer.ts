import { Customer } from '../../types';

export const mockCustomer: Customer = {
  id: 'cust-001',
  email: 'jordan.mitchell@email.com',
  given_name: 'Jordan',
  family_name: 'Mitchell',
  phone: '+1 (212) 555-0147',
  dateOfBirth: '1990-07-22',
  address: {
    street: '123 Oak Street Apt 4B',
    city: 'New York',
    state: 'NY',
    zip: '10001',
    country: 'US',
  },
  memberSince: '2019-03-15',
  preferredName: null,
};
