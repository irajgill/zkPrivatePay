import React, { useState } from 'react';
import TransferForm from './TransferForm';
import FXTrade from './FXTrade';

export default function Dashboard() {
  return (
    <div style={{ maxWidth: 960, margin: '40px auto', padding: 16 }}>
      <h1>zkPrivatePay</h1>
      <p>Confidential, compliant cross‑border payments on Aptos.</p>
      <TransferForm />
      <FXTrade />
    </div>
  );
}
