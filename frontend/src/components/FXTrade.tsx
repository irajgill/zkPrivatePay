import React, { useState } from 'react';
import axios from 'axios';

export default function FXTrade() {
  const [pair, setPair] = useState('USDC/EURC');
  const [notional, setNotional] = useState('100');
  const [status, setStatus] = useState<string | null>(null);

  const submit = async () => {
    setStatus('Submitting private order...');
    const commitment = new TextEncoder().encode(JSON.stringify({ pair, notional }));
    const res = await axios.post('/api/clob/order', { commitment: Buffer.from(commitment).toString('hex') });
    setStatus(`Order ID: ${res.data.orderId}`);
  };

  return (
    <div style={{ marginTop: 24, padding: 16, border: '1px solid #ddd', borderRadius: 8 }}>
      <h3>Private FX Order</h3>
      <div style={{ display: 'flex', gap: 8 }}>
        <input value={pair} onChange={e => setPair(e.target.value)} />
        <input type="number" value={notional} onChange={e => setNotional(e.target.value)} />
        <button onClick={submit}>Submit</button>
      </div>
      {status && <p style={{ marginTop: 8 }}>{status}</p>}
    </div>
  );
}
