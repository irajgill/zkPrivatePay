import { Router } from 'express';
import { getOraclePubs } from '../services/complianceOracle.js';
const r = Router();
r.get('/oracles', (_req, res) => {
    res.json({ pubs: getOraclePubs() });
});
export default r;
