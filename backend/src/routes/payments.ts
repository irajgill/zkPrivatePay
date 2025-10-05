import express from 'express';
import {z} from 'zod';
import {cfg} from '../config.js';
import {Database} from '../db/index.js';

const router = express.Router();

// Validation schemas
const ConfidentialPaymentSchema = z.object({
  proofJobId: z.string().uuid(),
  attesters: z.array(z.string()),
  signatures: z.array(z.string()),
  nullifiers: z.array(z.string()),
  commitments: z.array(z.string()),
  feePaid: z.string(),
  newStateRoot: z.string()
});

const WithdrawSchema = z.object({
  proofJobId: z.string().uuid(),
  attesters: z.array(z.string()),
  signatures: z.array(z.string()),
  recipient: z.string(),
  amount: z.string()
});

// Submit confidential payment
router.post('/confidential', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const {
      proofJobId,
      attesters,
      signatures,
      nullifiers,
      commitments,
      feePaid,
      newStateRoot
    } = ConfidentialPaymentSchema.parse(req.body);
    
    // Verify proof job exists and is completed
    const proofJob = await Database.getProofJob(proofJobId);
    if (!proofJob || proofJob.status !== 'completed') {
      return res.status(400).json({ error: 'Invalid or incomplete proof job' });
    }
    
    const user = await Database.getOrCreateUser(aptosAddress);
    
    // Create transaction payload
    const payload = {
      type: 'entry_function_payload',
      function: `${cfg.contractAddress}::zk_private_pay_manager::apply_confidential_payment`,
      type_arguments: ['0x1::aptos_coin::AptosCoin'],
      arguments: [
        attesters,
        signatures,
        proofJob.proof_data ? JSON.stringify(proofJob.proof_data) : '{}',
        `tx_${Date.now()}`, // tx_id
        nullifiers,
        commitments,
        feePaid,
        newStateRoot
      ]
    };
    
    // Store payment record
    const paymentId = await Database.createPayment(
      user.id,
      nullifiers,
      commitments,
      BigInt(feePaid)
    );
    
    res.json({
      paymentId,
      payload,
      proofHash: proofJob.proof_data?.proofHash || null,
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Confidential payment failed:', error);
    res.status(400).json({
      error: error instanceof z.ZodError ? 'Invalid input data' : (error as Error).message
    });
  }
});

// Process withdrawal
router.post('/withdraw', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const {
      proofJobId,
      attesters, 
      signatures,
      recipient,
      amount
    } = WithdrawSchema.parse(req.body);
    
    const proofJob = await Database.getProofJob(proofJobId);
    if (!proofJob || proofJob.status !== 'completed') {
      return res.status(400).json({ error: 'Invalid or incomplete proof job' });
    }
    
    const payload = {
      type: 'entry_function_payload',
      function: `${cfg.contractAddress}::zk_private_pay_manager::withdraw`,
      type_arguments: ['0x1::aptos_coin::AptosCoin'],
      arguments: [
        recipient,
        attesters,
        signatures,
        proofJob.proof_data ? JSON.stringify(proofJob.proof_data) : '{}',
        amount
      ]
    };
    
    res.json({
      payload,
      proofHash: proofJob.proof_data?.proofHash || null,
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Withdrawal failed:', error);
    res.status(400).json({
      error: error instanceof z.ZodError ? 'Invalid input data' : (error as Error).message
    });
  }
});

// Deposit funds
router.post('/deposit', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const { amount, recipientCommitment } = req.body;
    
    if (!amount || !recipientCommitment) {
      return res.status(400).json({ error: 'Amount and recipient commitment required' });
    }
    
    const payload = {
      type: 'entry_function_payload',
      function: `${cfg.contractAddress}::zk_private_pay_manager::deposit`,
      type_arguments: ['0x1::aptos_coin::AptosCoin'],
      arguments: [
        amount,
        recipientCommitment
      ]
    };
    
    res.json({
      payload,
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Deposit failed:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user payment history
router.get('/history', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const user = await Database.getOrCreateUser(aptosAddress);
    
    // Get user payments (implement this query in Database class)
    // const payments = await Database.getUserPayments(user.id);
    
    res.json({
      // payments,
      message: 'Payment history endpoint - implement getUserPayments query',
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Get payment history failed:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
