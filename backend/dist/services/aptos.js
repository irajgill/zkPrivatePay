import { Account, Aptos, AptosConfig, Ed25519PrivateKey, Network } from '@aptos-labs/ts-sdk';
import { cfg } from '../config.js';
export class AptosService {
    aptos;
    account;
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
    async getAccount(address) {
        const accountAddress = address || this.account.accountAddress.toString();
        return await this.aptos.getAccountInfo({ accountAddress });
    }
    /**
     * Get account balance
     */
    async getBalance(address) {
        const accountAddress = address || this.account.accountAddress.toString();
        const resources = await this.aptos.getAccountResources({ accountAddress });
        const coinStore = resources.find((r) => r.type === '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>');
        return coinStore ? parseInt(coinStore.data.coin.value) : 0;
    }
    /**
     * Initialize zkPrivatePay vault
     */
    async initializeVault(adminAddress, feeBps = 100) {
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
    async registerVerifier(verifierAddress, pubkey) {
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
    async submitConfidentialPayment(attesters, signatures, proofHash, nullifiers, commitments, feePaid, newStateRoot) {
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
    async processWithdrawal(recipient, attesters, signatures, proofHash, amount) {
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
    async getStateRoot() {
        const accountAddress = cfg.contractAddress;
        const resource = await this.aptos.getAccountResource({
            accountAddress,
            resourceType: `${cfg.contractAddress}::zk_private_pay_manager::Vault<0x1::aptos_coin::AptosCoin>`
        });
        return resource.state_root;
    }
    /**
     * Check if nullifier is spent
     */
    async isNullifierSpent(nullifier) {
        try {
            const accountAddress = cfg.contractAddress;
            const resource = await this.aptos.getAccountResource({
                accountAddress,
                resourceType: `${cfg.contractAddress}::zk_private_pay_manager::Vault<0x1::aptos_coin::AptosCoin>`
            });
            const nullifiers = resource.nullifiers;
            return nullifiers && nullifiers[nullifier] === true;
        }
        catch (error) {
            console.error('Error checking nullifier:', error);
            return false;
        }
    }
    /**
     * Wait for transaction confirmation
     */
    async waitForTransaction(txnHash) {
        return await this.aptos.waitForTransaction({ transactionHash: txnHash });
    }
    /**
     * Get transaction by hash
     */
    async getTransaction(txnHash) {
        return await this.aptos.getTransactionByHash({ transactionHash: txnHash });
    }
}
export const aptosService = new AptosService();
