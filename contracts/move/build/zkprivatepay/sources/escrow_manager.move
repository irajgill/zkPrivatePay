module zkprivatepay::escrow_manager {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aptos_std::table::{Self as table, Table};
    use zkprivatepay::zk_payment_verifier;

    struct Escrow<phantom T> has key {
        next_id: u64,
        vault: coin::Coin<T>,
        escrows: Table<u64, EscrowInfo>,
    }

    struct EscrowInfo has copy, drop, store {
        payer: address,
        payee: address,
        amount: u64,
        predicate_commitment: vector<u8>,
        expiry_sec: u64,
        claimed: bool,
    }

    public fun init<T>(account: &signer) {
        move_to(account, Escrow<T> { 
            next_id: 1, 
            vault: coin::zero<T>(), 
            escrows: table::new<u64, EscrowInfo>() 
        });
    }

    public fun open<T>(user: &signer, payee: address, amount: u64, predicate_commitment: vector<u8>, expiry_sec: u64) {
        let addr = signer::address_of(user);
        assert!(exists<Escrow<T>>(addr), 1);
        
        let e = borrow_global_mut<Escrow<T>>(addr);
        let coins = coin::withdraw<T>(user, amount);
        coin::merge(&mut e.vault, coins);
        let id = e.next_id;
        let info = EscrowInfo { 
            payer: addr, 
            payee, 
            amount, 
            predicate_commitment, 
            expiry_sec, 
            claimed: false 
        };
        table::add(&mut e.escrows, id, info);
        e.next_id = id + 1;
    }

    public fun claim<T>(admin: &signer, id: u64, attesters: vector<address>, sigs: vector<vector<u8>>, predicate_proof_hash: vector<u8>) {
        let addr = signer::address_of(admin);
        assert!(exists<Escrow<T>>(addr), 1);
        
        let ok = zk_payment_verifier::verify_attestation(admin, attesters, sigs, predicate_proof_hash, b"escrow_claim");
        assert!(ok, 1);
        
        let e = borrow_global_mut<Escrow<T>>(addr);
        let info = table::borrow_mut(&mut e.escrows, id);
        assert!(!info.claimed, 2);
        let coins = coin::extract<T>(&mut e.vault, info.amount);
        coin::deposit<T>(info.payee, coins);
        info.claimed = true;
    }

    public fun refund<T>(admin: &signer, id: u64) {
        let addr = signer::address_of(admin);
        assert!(exists<Escrow<T>>(addr), 3);
        
        let e = borrow_global_mut<Escrow<T>>(addr);
        let info = table::borrow_mut(&mut e.escrows, id);
        assert!(timestamp::now_seconds() > info.expiry_sec, 3);
        assert!(!info.claimed, 4);
        let coins = coin::extract<T>(&mut e.vault, info.amount);
        coin::deposit<T>(info.payer, coins);
        info.claimed = true;
    }
}
