import React, { useState, useMemo, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Box, Typography, MenuItem, TextField } from '@mui/material';
import { useAccounts } from '../hooks/useAccounts';
import { getAllTransactions } from '../services/transaction.service';
import { Transaction, TransactionFilters } from '../types';
import TransactionFilter from '../components/transactions/TransactionFilter';
import TransactionTable from '../components/transactions/TransactionTable';

const DEFAULT_FILTERS: TransactionFilters = {
  search: '', startDate: '', endDate: '', type: '', status: '', accountId: '',
};

export default function TransactionHistoryPage() {
  const [searchParams] = useSearchParams();
  const { accounts } = useAccounts();
  const [allTxns, setAllTxns] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<TransactionFilters>({
    ...DEFAULT_FILTERS,
    accountId: searchParams.get('account') ?? '',
  });

  useEffect(() => {
    getAllTransactions().then(setAllTxns).finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    return allTxns
      .filter((t) => !filters.accountId || t.accountId === filters.accountId)
      .filter((t) => !filters.type || t.type === filters.type)
      .filter((t) => !filters.status || t.status === filters.status)
      .filter((t) => {
        if (!filters.search) return true;
        const q = filters.search.toLowerCase();
        return t.description.toLowerCase().includes(q) || (t.merchantName?.toLowerCase().includes(q) ?? false);
      })
      .filter((t) => !filters.startDate || t.date >= filters.startDate)
      .filter((t) => !filters.endDate || t.date <= filters.endDate)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [allTxns, filters]);

  return (
    <Box>
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={3} flexWrap="wrap" gap={2}>
        <Box>
          <Typography variant="h2">Transaction History</Typography>
          <Typography variant="body2" color="text.secondary">{filtered.length} transactions found</Typography>
        </Box>
        {accounts.length > 0 && (
          <TextField
            select size="small" label="Account" value={filters.accountId}
            onChange={(e) => setFilters({ ...filters, accountId: e.target.value })}
            sx={{ minWidth: 200 }}
          >
            <MenuItem value="">All Accounts</MenuItem>
            {accounts.map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.nickname ?? a.maskedAccountNumber}</MenuItem>
            ))}
          </TextField>
        )}
      </Box>

      <TransactionFilter
        filters={filters}
        onChange={setFilters}
        onReset={() => setFilters(DEFAULT_FILTERS)}
      />

      <TransactionTable transactions={filtered} loading={loading} />
    </Box>
  );
}
