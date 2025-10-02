import { Router } from 'express';
const r = Router();
r.post('/order', async (req, res) => {
    // accept private order commitment
    const { commitment } = req.body;
    res.json({ orderId: 1, commitment });
});
export default r;
