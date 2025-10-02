module zkprivatepay::clob_connector {
    use std::signer;
    use aptos_std::table::{Self as table, Table};
    use zkprivatepay::zk_payment_verifier;

    struct Orders has key {
        next_id: u64,
        commitments: Table<u64, vector<u8>>,
        fills: Table<u64, vector<u8>>,
    }

    public fun init(account: &signer) {
        move_to(account, Orders { 
            next_id: 1, 
            commitments: table::new<u64, vector<u8>>(), 
            fills: table::new<u64, vector<u8>>() 
        });
    }

    public fun submit_private_order(account: &signer, commitment: vector<u8>): u64 acquires Orders {
        let o = borrow_global_mut<Orders>(signer::address_of(account));
        let id = o.next_id;
        table::add(&mut o.commitments, id, commitment);
        o.next_id = id + 1;
        id
    }

    public fun settle_fill(account: &signer, order_id: u64, attesters: vector<address>, sigs: vector<vector<u8>>, fill_hash: vector<u8>) acquires Orders {
        let ok = zk_payment_verifier::verify_attestation(account, attesters, sigs, fill_hash, b"clob_fill");
        assert!(ok, 1);
        let o = borrow_global_mut<Orders>(signer::address_of(account));
        table::add(&mut o.fills, order_id, fill_hash);
    }
}


