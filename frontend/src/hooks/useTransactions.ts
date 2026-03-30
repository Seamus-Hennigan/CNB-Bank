import { useState, useEffect } from 'react';
import { Transaction } from '../types';
import { getTransactions } from '../services/transaction.service';

export function useTransactions(accountId: string | null) {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!accountId) return;
    setLoading(true);
    getTransactions(accountId)
      .then(setTransactions)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [accountId]);

  return { transactions, loading, error };
}
