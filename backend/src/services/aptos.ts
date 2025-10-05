import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    Network
} from '@aptos-labs/ts-sdk';
import {cfg} from '../config.js';

export class AptosService {
  private aptos: Aptos;
  private account: Account;
  
  constructor() {
    const config = new AptosConfig({ network: Network.TESTNET });
    this.aptos = new Aptos(config);
    
    // Parse ed25519 private key
    const privateKeyHex = cfg.aptosPrivateKey
      .replace('ed25519-priv-0x', '')
      .replace('0x', '');
    
    const privateKey = new Ed25519PrivateKey(privateKeyHex);
    this.account = Account.fromPrivateKey({ privateKey });
  }

  /**
   * Get account info from Aptos testnet
   */
  async getAccount(address?: string): Promise<any> {
    const accountAddress = address || this.account.accountAddress.toString();
    return await this.aptos.getAccountInfo({ accountAddress });
  }

  /**
   * Get account balance
   */
  async getBalance(address?: string): Promise<number> {
    const accountAddress = address || this.account.accountAddress.toString();
    const resources = await this.aptos.getAccountResources({ accountAddress });
    
    const coinStore = resources.find(
      (r: any) => r.type === '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>'
    );
    
    return coinStore ? parseInt((coinStore.data as any).coin.value) : 0;
  }

  /**
   * Initialize zkPrivatePay vault
   */
  async initializeVault(adminAddress: string, feeBps: number = 100): Promise<string> {
    const transaction = await this.aptos.transaction.build.simple({
      sender: this.account.accountAddress,
      data: {
        function: `${cfg.contractAddress}::zk_private_pay_manager::init`,
        typeArguments: [],
        functionArguments: [adminAddress, feeBps]
      }
    });

    const committedTxn = await this.aptos.signAndSubmitTransaction({
      signer: this.account,
      transaction
    });
    
    return committedTxn.hash;
  }

  /**
   * Register ZK verifier
   */
  async registerVerifier(verifierAddress: string, pubkey: string): Promise<string> {
    const transaction = await this.aptos.transaction.build.simple({
      sender: this.account.accountAddress,
      data: {
        function: `${cfg.contractAddress}::zk_payment_verifier::register_verifier`,
        typeArguments: [],
        functionArguments: [verifierAddress, pubkey]
      }
    });

    const committedTxn = await this.aptos.signAndSubmitTransaction({
      signer: this.account,
      transaction
    });
    
    return committedTxn.hash;
  }

  /**
   * Submit confidential payment transaction
   */
  async submitConfidentialPayment(
    attesters: string[],
    signatures: string[], 
    proofHash: string,
    nullifiers: string[],
    commitments: string[],
    feePaid: string,
    newStateRoot: string
  ): Promise<string> {
    const txId = `tx_${Date.now()}`;
    
    const transaction = await this.aptos.transaction.build.simple({
      sender: this.account.accountAddress,
      data: {
        function: `${cfg.contractAddress}::zk_private_pay_manager::apply_confidential_payment`,
        typeArguments: ['0x1::aptos_coin::AptosCoin'],
        functionArguments: [
          attesters,
          signatures,
          proofHash,
          txId,
          nullifiers,
          commitments,
          feePaid,
          newStateRoot
        ]
      }
    });

    const committedTxn = await this.aptos.signAndSubmitTransaction({
      signer: this.account,
      transaction
    });
    
    return committedTxn.hash;
  }

  /**
   * Process withdrawal
   */
  async processWithdrawal(
    recipient: string,
    attesters: string[],
    signatures: string[],
    proofHash: string,
    amount: string
  ): Promise<string> {
    const transaction = await this.aptos.transaction.build.simple({
      sender: this.account.accountAddress,
      data: {
        function: `${cfg.contractAddress}::zk_private_pay_manager::withdraw`,
        typeArguments: ['0x1::aptos_coin::AptosCoin'],
        functionArguments: [
          recipient,
          attesters,
          signatures,
          proofHash,
          amount
        ]
      }
    });

    const committedTxn = await this.aptos.signAndSubmitTransaction({
      signer: this.account,
      transaction
    });
    
    return committedTxn.hash;
  }

  /**
   * Get current state root
   */
  async getStateRoot(): Promise<string> {
    const accountAddress = cfg.contractAddress;
    const resource = await this.aptos.getAccountResource({
      accountAddress,
      resourceType: `${cfg.contractAddress}::zk_private_pay_manager::Vault<0x1::aptos_coin::AptosCoin>`
    });
    
    return (resource as any).state_root;
  }

  /**
   * Check if nullifier is spent
   */
  async isNullifierSpent(nullifier: string): Promise<boolean> {
    try {
      const accountAddress = cfg.contractAddress;
      const resource = await this.aptos.getAccountResource({
        accountAddress,
        resourceType: `${cfg.contractAddress}::zk_private_pay_manager::Vault<0x1::aptos_coin::AptosCoin>`
      });
      
      const nullifiers = (resource as any).nullifiers;
      return nullifiers && nullifiers[nullifier] === true;
    } catch (error) {
      console.error('Error checking nullifier:', error);
      return false;
    }
  }

  /**
   * Wait for transaction confirmation
   */
  async waitForTransaction(txnHash: string): Promise<any> {
    return await this.aptos.waitForTransaction({ transactionHash: txnHash });
  }

  /**
   * Get transaction by hash
   */
  async getTransaction(txnHash: string): Promise<any> {
    return await this.aptos.getTransactionByHash({ transactionHash: txnHash });
  }
}

export const aptosService = new AptosService();
