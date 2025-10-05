import {Pool} from 'pg';
import {cfg} from '../config.js';

export const pool = new Pool({
  connectionString: cfg.databaseUrl,
  ssl: cfg.nodeEnv === 'production' ? { rejectUnauthorized: false } : false,
});

export interface User {
  id: number;
  aptos_address: string;
  created_at: Date;
  last_active: Date;
}

export interface ProofJob {
  id: string;
  user_id: number;
  circuit_type: 'payment' | 'kyc';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  input_data: any;
  proof_data?: any;
  public_signals?: any;
  error_message?: string;
  created_at: Date;
  completed_at?: Date;
}

export interface Payment {
  id: string;
  user_id: number;
  tx_hash?: string;
  nullifiers: string[];
  commitments: string[];
  amount?: bigint;
  fee?: bigint;
  status: string;
  created_at: Date;
}

export class Database {
  static async getOrCreateUser(aptosAddress: string): Promise<User> {
    const client = await pool.connect();
    try {
      // Try to get existing user
      let result = await client.query(
        'SELECT * FROM users WHERE aptos_address = $1',
        [aptosAddress]
      );
      
      if (result.rows.length > 0) {
        // Update last active
        await client.query(
          'UPDATE users SET last_active = NOW() WHERE id = $1',
          [result.rows[0].id]  // Fixed: access first row
        );
        return result.rows[0];  // Fixed: return first row
      }
      
      // Create new user
      result = await client.query(
        'INSERT INTO users (aptos_address) VALUES ($1) RETURNING *',
        [aptosAddress]
      );
      
      return result.rows[0];  // Fixed: return first row
    } finally {
      client.release();
    }
  }
  
  static async createProofJob(userId: number, circuitType: 'payment' | 'kyc', inputData: any): Promise<string> {
    const client = await pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO proof_jobs (user_id, circuit_type, input_data) VALUES ($1, $2, $3) RETURNING id',
        [userId, circuitType, JSON.stringify(inputData)]
      );
      return result.rows[0].id;  // Fixed: access first row
    } finally {
      client.release();
    }
  }
  
  static async updateProofJob(jobId: string, status: string, proofData?: any, publicSignals?: any, errorMessage?: string): Promise<void> {
    const client = await pool.connect();
    try {
      await client.query(
        `UPDATE proof_jobs 
         SET status = $1, proof_data = $2, public_signals = $3, error_message = $4, completed_at = NOW() 
         WHERE id = $5`,
        [status, proofData ? JSON.stringify(proofData) : null, publicSignals ? JSON.stringify(publicSignals) : null, errorMessage, jobId]
      );
    } finally {
      client.release();
    }
  }
  
  static async getProofJob(jobId: string): Promise<ProofJob | null> {
    const client = await pool.connect();
    try {
      const result = await client.query('SELECT * FROM proof_jobs WHERE id = $1', [jobId]);
      return result.rows.length > 0 ? result.rows[0] : null;  // Fixed: return first row
    } finally {
      client.release();
    }
  }
  
  static async createPayment(userId: number, nullifiers: string[], commitments: string[], amount?: bigint, fee?: bigint): Promise<string> {
    const client = await pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO payments (user_id, nullifiers, commitments, amount, fee) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [userId, JSON.stringify(nullifiers), JSON.stringify(commitments), amount?.toString(), fee?.toString()]
      );
      return result.rows[0].id;  // Fixed: access first row
    } finally {
      client.release();
    }
  }
}
