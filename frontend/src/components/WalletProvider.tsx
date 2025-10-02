import React from 'react';
import { useWallet } from '@aptos-labs/wallet-adapter-react';

export default function WalletProvider({ children }: { children: React.ReactNode }) {
  // In real app, configure Martian, Petra, Fewcha etc.
  return <>{children}</>;
}
