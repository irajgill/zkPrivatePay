import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import {groth16} from 'snarkjs';
import {cfg} from '../config.js';

export interface ProofInput {
  // Payment circuit inputs
  root?: string;
  fee?: string;
  in_amounts?: string[];
  in_blindings?: string[];
  in_pks?: string[];
  in_sks?: string[];
  merkle_path_elements?: string[][];
  merkle_path_index?: string[][];
  out_amounts?: string[];
  out_blindings?: string[];
  out_pks?: string[];
  
  // KYC circuit inputs
  identity_secret?: string;
  country_code?: string;
  age?: string;
  identity_nullifier?: string;
  country_nullifier?: string;
  identity_path_elements?: string[];
  identity_path_indices?: string[];
  country_path_elements?: string[];
  country_path_indices?: string[];
}

export async function provePayment(input: ProofInput) {
  try {
    const circuitsDir = cfg.circuitsPath;
    const wasm = path.join(circuitsDir, 'payment_js', 'payment.wasm');
    const zkey = path.join(circuitsDir, 'payment_final.zkey');
    
    // Validate files exist
    await fs.access(wasm);
    await fs.access(zkey);
    
    const { proof, publicSignals } = await groth16.fullProve(input, wasm, zkey);
    
    // Generate proof hash for attestation
    const proofHash = crypto
      .createHash('sha256')
      .update(JSON.stringify({ proof, publicSignals }))
      .digest('hex');
    
    return { 
      proof, 
      publicSignals, 
      proofHash: `0x${proofHash}`,
      timestamp: Date.now()
    };
  } catch (error) {
    console.error('Payment proof generation failed:', error);
    throw new Error(`Proof generation failed: ${(error as Error).message}`);
  }
}

export async function proveKyc(input: ProofInput) {
  try {
    const circuitsDir = cfg.circuitsPath;
    const wasm = path.join(circuitsDir, 'kyc_selective_disclosure_js', 'kyc_selective_disclosure.wasm');
    const zkey = path.join(circuitsDir, 'kyc_final.zkey');
    
    await fs.access(wasm);
    await fs.access(zkey);
    
    const { proof, publicSignals } = await groth16.fullProve(input, wasm, zkey);
    
    const proofHash = crypto
      .createHash('sha256')
      .update(JSON.stringify({ proof, publicSignals }))
      .digest('hex');
    
    return { 
      proof, 
      publicSignals, 
      proofHash: `0x${proofHash}`,
      timestamp: Date.now()
    };
  } catch (error) {
    console.error('KYC proof generation failed:', error);
    throw new Error(`KYC proof generation failed: ${(error as Error).message}`);
  }
}

export async function verifyProof(proof: any, publicSignals: any[], circuitType: 'payment' | 'kyc') {
  try {
    const circuitsDir = cfg.circuitsPath;
    const vkeyPath = path.join(circuitsDir, `${circuitType}_vkey.json`);
    
    const vkeyData = await fs.readFile(vkeyPath, 'utf8');
    const vkey = JSON.parse(vkeyData);
    
    return await groth16.verify(vkey, publicSignals, proof);
  } catch (error) {
    console.error('Proof verification failed:', error);
    return false;
  }
}
