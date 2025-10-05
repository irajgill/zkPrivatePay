module zkprivatepay::zk_private_pay_manager {
    use std::signer;
    use std::vector;
    use aptos_framework::coin;
    use aptos_std::table::{Self as table, Table};
    use zkprivatepay::events;
    use zkprivatepay::zk_payment_verifier;

    struct Vault<phantom T> has key {
        balance: coin::Coin<T>,
        events: events::Events,
        nullifiers: Table<vector<u8>, bool>,
        state_root: vector<u8>,
        admin: address,
        fee_bps: u64,
    }

    public entry fun init<T>(account: &signer, admin: address, fee_bps: u64) {
        let events_resource = events::init(account);
        move_to(account, Vault<T> {
            balance: coin::zero<T>(),
            events: events_resource,
            nullifiers: table::new<vector<u8>, bool>(),
            state_root: vector::empty<u8>(),
            admin,
            fee_bps
        });
    }

    public entry fun deposit<T>(user: &signer, amount: u64, recipient_commitment: vector<u8>) {
        let addr = signer::address_of(user);
        assert!(exists<Vault<T>>(addr), 1);
        
        let v = borrow_global_mut<Vault<T>>(addr);
        let coins = coin::withdraw<T>(user, amount);
        coin::merge(&mut v.balance, coins);
        events::emit_payment(&mut v.events, b"deposit", vector::empty<vector<u8>>(), vector::singleton<vector<u8>>(recipient_commitment), 0);
    }

    public entry fun apply_confidential_payment<T>(
        admin: &signer,
        attesters: vector<address>,
        sigs: vector<vector<u8>>,
        proof_hash: vector<u8>,
        tx_id: vector<u8>,
        nullifiers: vector<vector<u8>>,
        commitments: vector<vector<u8>>,
        fee_paid: u64,
        new_state_root: vector<u8>
    ) {
        let addr = signer::address_of(admin);
        assert!(exists<Vault<T>>(addr), 1);
        
        let v = borrow_global_mut<Vault<T>>(addr);
        let ok = zk_payment_verifier::verify_attestation(admin, attesters, sigs, proof_hash, b"payment");
        assert!(ok, 1);

        let n = vector::length(&nullifiers);
        let mut_i = 0;
        while (mut_i < n) {
            let nf = *vector::borrow(&nullifiers, mut_i);
            assert!(!table::contains(&v.nullifiers, nf), 2);
            table::add(&mut v.nullifiers, nf, true);
            mut_i = mut_i + 1;
        };

        v.state_root = new_state_root;
        events::emit_payment(&mut v.events, tx_id, nullifiers, commitments, fee_paid);
    }

    public entry fun withdraw<T>(
        admin: &signer,
        to: address,
        attesters: vector<address>,
        sigs: vector<vector<u8>>,
        proof_hash: vector<u8>,
        amount: u64
    ) {
        let addr = signer::address_of(admin);
        assert!(exists<Vault<T>>(addr), 3);
        
        let ok = zk_payment_verifier::verify_attestation(admin, attesters, sigs, proof_hash, b"withdraw");
        assert!(ok, 3);

        let v = borrow_global_mut<Vault<T>>(addr);
        let coins = coin::extract<T>(&mut v.balance, amount);
        coin::deposit<T>(to, coins);
    }

    public entry fun sweep_fees<T>(admin: &signer, to: address, amount: u64) {
        let addr = signer::address_of(admin);
        assert!(exists<Vault<T>>(addr), 1);
        
        let v = borrow_global_mut<Vault<T>>(addr);
        let coins = coin::extract<T>(&mut v.balance, amount);
        coin::deposit<T>(to, coins);
    }

    #[view]
    public fun get_state_root<T>(addr: address): vector<u8> acquires Vault {
        assert!(exists<Vault<T>>(addr), 1);
        borrow_global<Vault<T>>(addr).state_root
    }
}

