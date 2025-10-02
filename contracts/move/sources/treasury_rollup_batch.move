module zkprivatepay::treasury_rollup_batch {
    use std::signer;
    use aptos_std::table::{Self as table, Table};
    use zkprivatepay::events;
    use zkprivatepay::zk_payment_verifier;

    struct Rollup has key {
        next_batch_id: u64,
        state_root: vector<u8>,
        pending: Table<u64, vector<u8>>,
        events: events::Events,
    }

    public fun init(account: &signer, initial_root: vector<u8>) {
        let ev = events::init(account);
        move_to(account, Rollup { 
            next_batch_id: 1, 
            state_root: initial_root, 
            pending: table::new<u64, vector<u8>>(), 
            events: ev 
        });
    }

    public fun submit_batch(account: &signer, attesters: vector<address>, sigs: vector<vector<u8>>, proof_hash: vector<u8>, new_root: vector<u8>) acquires Rollup {
        let ok = zk_payment_verifier::verify_attestation(account, attesters, sigs, proof_hash, b"rollup");
        assert!(ok, 1);
        let r = borrow_global_mut<Rollup>(signer::address_of(account));
        let id = r.next_batch_id;
        table::add(&mut r.pending, id, new_root);
        r.next_batch_id = id + 1;
    }

    public fun apply(account: &signer, batch_id: u64) acquires Rollup {
        let r = borrow_global_mut<Rollup>(signer::address_of(account));
        let root = table::remove(&mut r.pending, batch_id);
        r.state_root = root;
        events::emit_rollup(&mut r.events, batch_id, r.state_root);
    }

    public fun state_root(addr: address): vector<u8> acquires Rollup { 
        borrow_global<Rollup>(addr).state_root 
    }
}

