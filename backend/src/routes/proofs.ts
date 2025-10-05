import {Queue, Worker} from 'bullmq';
import express from 'express';
import Redis from 'ioredis';
import {z} from 'zod';
import {cfg} from '../config.js';
import {Database} from '../db/index.js';
import {proveKyc, provePayment, verifyProof} from '../services/prover.js';

const router = express.Router();

// Fixed: Configure Redis for BullMQ compatibility
const redis = new Redis(cfg.redisUrl, {
  maxRetriesPerRequest: null,
  enableReadyCheck: false
});

const proofQueue = new Queue('proof-generation', { connection: redis });

// Input validation schemas
const PaymentProofSchema = z.object({
  root: z.string(),
  fee: z.string(),
  in_amounts: z.array(z.string()),
  in_blindings: z.array(z.string()),
  in_pks: z.array(z.string()),
  in_sks: z.array(z.string()),
  merkle_path_elements: z.array(z.array(z.string())),
  merkle_path_index: z.array(z.array(z.string())),
  out_amounts: z.array(z.string()),
  out_blindings: z.array(z.string()),
  out_pks: z.array(z.string()),
});

const KycProofSchema = z.object({
  identity_secret: z.string(),
  country_code: z.string(),
  age: z.string(),
  identity_nullifier: z.string(),
  country_nullifier: z.string(),
  identity_path_elements: z.array(z.string()),
  identity_path_indices: z.array(z.string()),
  country_path_elements: z.array(z.string()),
  country_path_indices: z.array(z.string()),
});

// Background proof worker with proper Redis config
const proofWorker = new Worker('proof-generation', async (job) => {
  const { jobId, circuitType, inputData } = job.data;
  
  try {
    await Database.updateProofJob(jobId, 'processing');
    
    let result;
    if (circuitType === 'payment') {
      result = await provePayment(inputData);
    } else if (circuitType === 'kyc') {
      result = await proveKyc(inputData);
    } else {
      throw new Error(`Unknown circuit type: ${circuitType}`);
    }
    
    await Database.updateProofJob(jobId, 'completed', result.proof, result.publicSignals);
    
    return result;
  } catch (error) {
    await Database.updateProofJob(jobId, 'failed', null, null, (error as Error).message);
    throw error;
  }
}, { 
  connection: new Redis(cfg.redisUrl, {
    maxRetriesPerRequest: null,
    enableReadyCheck: false
  })
});

// Generate payment proof
router.post('/payment', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const inputData = PaymentProofSchema.parse(req.body);
    const user = await Database.getOrCreateUser(aptosAddress);
    
    // Create proof job
    const jobId = await Database.createProofJob(user.id, 'payment', inputData);
    
    // Queue for background processing
    await proofQueue.add('generate-proof', {
      jobId,
      circuitType: 'payment',
      inputData
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 5000,
      },
    });
    
    res.json({ 
      jobId,
      status: 'queued',
      estimatedTime: '30-60 seconds'
    });
    
  } catch (error) {
    console.error('Payment proof request failed:', error);
    res.status(400).json({ 
      error: error instanceof z.ZodError ? 'Invalid input data' : (error as Error).message
    });
  }
});

// Generate KYC proof  
router.post('/kyc', async (req, res) => {
  try {
    const aptosAddress = req.headers['x-aptos-address'] as string;
    if (!aptosAddress) {
      return res.status(401).json({ error: 'Aptos address required' });
    }
    
    const inputData = KycProofSchema.parse(req.body);
    const user = await Database.getOrCreateUser(aptosAddress);
    
    const jobId = await Database.createProofJob(user.id, 'kyc', inputData);
    
    await proofQueue.add('generate-proof', {
      jobId,
      circuitType: 'kyc', 
      inputData
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 5000,
      },
    });
    
    res.json({ 
      jobId,
      status: 'queued',
      estimatedTime: '20-40 seconds'
    });
    
  } catch (error) {
    console.error('KYC proof request failed:', error);
    res.status(400).json({ 
      error: error instanceof z.ZodError ? 'Invalid input data' : (error as Error).message
    });
  }
});

// Check proof job status
router.get('/:jobId', async (req, res) => {
  try {
    const { jobId } = req.params;
    const job = await Database.getProofJob(jobId);
    
    if (!job) {
      return res.status(404).json({ error: 'Proof job not found' });
    }
    
    // Don't expose sensitive input data in response
    const { input_data, ...safeJob } = job;
    
    res.json(safeJob);
    
  } catch (error) {
    console.error('Get proof job failed:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify proof (for testing)
router.post('/verify', async (req, res) => {
  try {
    const { proof, publicSignals, circuitType } = req.body;
    
    if (!['payment', 'kyc'].includes(circuitType)) {
      return res.status(400).json({ error: 'Invalid circuit type' });
    }
    
    const isValid = await verifyProof(proof, publicSignals, circuitType);
    
    res.json({ 
      valid: isValid,
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Proof verification failed:', error);
    res.status(400).json({ error: (error as Error).message });
  }
});

// Get proof queue statistics
router.get('/stats/queue', async (req, res) => {
  try {
    const waiting = await proofQueue.getWaiting();
    const active = await proofQueue.getActive();
    const completed = await proofQueue.getCompleted();
    const failed = await proofQueue.getFailed();
    
    res.json({
      queue: {
        waiting: waiting.length,
        active: active.length,
        completed: completed.length,
        failed: failed.length
      },
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error('Get queue stats failed:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
