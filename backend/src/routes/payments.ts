import { Router } from 'express';
import { notify } from '../services/telegram.js';

const r = Router();

r.post('/intent', async (req, res) => {
  // accept payment intent (mock)
  const { sender, recipient, amount } = req.body;
  // persist to db in production
  await notify(process.env.TELEGRAM_CHAT_ID || '', `Payment intent from ${sender} -> ${recipient} for ${amount}`);
  res.json({ ok: true });
});

export default r;
