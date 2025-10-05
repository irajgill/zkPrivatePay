import { Account, Ed25519PrivateKey } from '@aptos-labs/ts-sdk';
import dotenv from 'dotenv';

dotenv.config();

const privateKeyHex = process.env.APTOS_PRIVATE_KEY
  .replace('ed25519-priv-0x', '')
  .replace('0x', '');

try {
  const privateKey = new Ed25519PrivateKey(privateKeyHex);
  const account = Account.fromPrivateKey({ privateKey });
  console.log('✅ Account Address:', account.accountAddress.toString());
} catch (error) {
  console.error('❌ Error:', error.message);
}
