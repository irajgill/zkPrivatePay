import { Aptos, AptosConfig, Network, Account, Ed25519PrivateKey } from '@aptos-labs/ts-sdk';
import dotenv from 'dotenv';

dotenv.config();

const privateKeyHex = process.env.APTOS_PRIVATE_KEY
  .replace('ed25519-priv-0x', '')
  .replace('0x', '');

async function testBackendAptos() {
  try {
    // Initialize Aptos SDK
    const config = new AptosConfig({ network: Network.TESTNET });
    const aptos = new Aptos(config);
    
    // Create account from private key
    const privateKey = new Ed25519PrivateKey(privateKeyHex);
    const account = Account.fromPrivateKey({ privateKey });
    
    console.log('✅ Account derived:', account.accountAddress.toString());
    
    // Get account info
    const accountInfo = await aptos.getAccountInfo({ 
      accountAddress: account.accountAddress 
    });
    
    console.log('✅ Account info retrieved');
    console.log('   Sequence number:', accountInfo.sequence_number);
    
    // Get balance
    const resources = await aptos.getAccountResources({ 
      accountAddress: account.accountAddress 
    });
    
    const coinStore = resources.find(
      r => r.type === '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>'
    );
    
    if (coinStore) {
      const balance = coinStore.data.coin.value;
      const aptBalance = (balance / 100000000).toFixed(2);
      console.log('✅ Balance:', aptBalance, 'APT');
    }
    
    // Build a test transaction (don't submit)
    const transaction = await aptos.transaction.build.simple({
      sender: account.accountAddress,
      data: {
        function: "0x1::aptos_account::transfer",
        functionArguments: [account.accountAddress, 100],
      },
    });
    
    console.log('✅ Transaction building works');
    console.log('');
    console.log('🎉 Backend Aptos integration is WORKING!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

testBackendAptos();
