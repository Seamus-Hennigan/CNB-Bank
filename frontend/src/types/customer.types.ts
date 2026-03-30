export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
}

export interface Customer {
  id: string;
  email: string;
  given_name: string;
  family_name: string;
  phone: string;
  dateOfBirth: string;
  address: Address;
  memberSince: string;
  preferredName: string | null;
}
