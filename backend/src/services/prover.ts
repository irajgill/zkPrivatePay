import { groth16 } from 'snarkjs';
import fs from 'fs/promises';
import path from 'path';

export async function provePayment(input: any) {
  const dir = path.join(process.cwd(), '..', 'circuits', 'circom', 'build');
  const wasm = path.join(dir, 'payment_js', 'payment.wasm');
  const zkey = path.join(dir, 'payment_final.zkey');
  // This calls into snarkjs to generate a proof; in production, use a worker pool
  const { proof, publicSignals } = await groth16.fullProve(input, wasm, zkey);
  return { proof, publicSignals };
}

export async function proveKyc(input: any) {
  const dir = path.join(process.cwd(), '..', 'circuits', 'circom', 'build');
  const wasm = path.join(dir, 'kyc_selective_disclosure_js', 'kyc_selective_disclosure.wasm');
  const zkey = path.join(dir, 'kyc_final.zkey');
  const { proof, publicSignals } = await groth16.fullProve(input, wasm, zkey);
  return { proof, publicSignals };
}
