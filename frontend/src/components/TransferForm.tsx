import React, { useState } from 'react';
import axios from 'axios';
import { generateCommitment } from '../utils/encryption';

export default function TransferForm() {
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('0');
  const [status, setStatus] = useState<string | null>(null);

  const submit = async () => {
    setStatus('Generating proof...');
    const commitment = await generateCommitment(recipient, Number(amount));
    const res = await axios.post('/api/proofs/payment', {
      // Minimal input; in a real app include merkle paths etc.
      root: '0',
      fee: '0',
      in_amount0: amount,
      in_amount1: '0',
      out_amount0: amount,
      out_amount1: '0'
    });
    setStatus(`ProofHash: ${res.data.proofHash}`);
  };

  return (
    <div style={{ marginTop: 24, padding: 16, border: '1px solid #ddd', borderRadius: 8 }}>
      <h3>Send</h3>
      <div style={{ display: 'flex', gap: 8 }}>
        <input placeholder="Recipient" value={recipient} onChange={e => setRecipient(e.target.value)} />
        <input type="number" placeholder="Amount (USDC)" value={amount} onChange={e => setAmount(e.target.value)} />
        <button onClick={submit}>Prove & Send</button>
      </div>
      {status && <p style={{ marginTop: 8 }}>{status}</p>}
    </div>
  );
}
