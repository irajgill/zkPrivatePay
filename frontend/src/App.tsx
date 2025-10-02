import React from 'react';
import { AptosWalletAdapterProvider } from '@aptos-labs/wallet-adapter-react';
import WalletProvider from './components/WalletProvider';
import Dashboard from './components/Dashboard';

export default function App() {
  return (
    <AptosWalletAdapterProvider plugins={[]}>
      <WalletProvider>
        <Dashboard />
      </WalletProvider>
    </AptosWalletAdapterProvider>
  );
}
