import { Router } from 'express';
import { provePayment, proveKyc } from '../services/prover.js';
import { attest, hash } from '../services/complianceOracle.js';
const r = Router();
r.post('/payment', async (req, res) => {
    const input = req.body;
    const { proof, publicSignals } = await provePayment(input);
    const proofHash = hash(Buffer.from(JSON.stringify({ proof, publicSignals })));
    const att = attest('zkPP:attest:', proofHash);
    res.json({ proof, publicSignals, attestation: att, proofHash: Buffer.from(proofHash).toString('hex') });
});
r.post('/kyc', async (req, res) => {
    const input = req.body;
    const { proof, publicSignals } = await proveKyc(input);
    const proofHash = hash(Buffer.from(JSON.stringify({ proof, publicSignals })));
    const att = attest('zkPP:kyc:', proofHash);
    res.json({ proof, publicSignals, attestation: att, proofHash: Buffer.from(proofHash).toString('hex') });
});
export default r;
