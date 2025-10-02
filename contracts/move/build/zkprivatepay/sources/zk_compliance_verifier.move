module zkprivatepay::zk_compliance_verifier {
    use std::signer;
    use std::vector;
    use aptos_framework::ed25519;
    use aptos_std::table::{Self as table, Table};

    const E_NOT_AUTHORIZED: u64 = 1;

    struct OracleSet has key {
        quorum: u8,
        keys: Table<address, vector<u8>>,
        latest_identity_root: vector<u8>,
        latest_country_root: vector<u8>,
        min_age: u64,
    }

    public fun init(account: &signer, quorum: u8, min_age: u64) {
        move_to(account, OracleSet {
            quorum,
            keys: table::new<address, vector<u8>>(),
            latest_identity_root: vector::empty<u8>(),
            latest_country_root: vector::empty<u8>(),
            min_age
        });
    }

    public fun register_oracle(account: &signer, addr: address, pubkey: vector<u8>) acquires OracleSet {
        let set = borrow_global_mut<OracleSet>(signer::address_of(account));
        table::add(&mut set.keys, addr, pubkey);
    }

    public fun update_roots(account: &signer, id_root: vector<u8>, country_root: vector<u8>, min_age: u64) acquires OracleSet {
        let set = borrow_global_mut<OracleSet>(signer::address_of(account));
        set.latest_identity_root = id_root;
        set.latest_country_root = country_root;
        set.min_age = min_age;
    }

    public fun verify_kyc_attestation(
        account: &signer,
        attesters: vector<address>,
        sigs: vector<vector<u8>>,
        kyc_proof_hash: vector<u8>,
        session_nullifier: vector<u8>
    ): bool acquires OracleSet {
        let set = borrow_global<OracleSet>(signer::address_of(account));
        let n = vector::length(&attesters);
        let ok: u64 = 0;
        let mut_i = 0;  // Declare variable
        while (mut_i < n) {
            let who = *vector::borrow(&attesters, mut_i);
            let sig_bytes = vector::borrow(&sigs, mut_i);
            if (table::contains(&set.keys, who)) {
                let pk_bytes = table::borrow(&set.keys, who);
                let msg = vector::empty<u8>();
                vector::append(&mut msg, b"zkPP:kyc:");
                vector::append(&mut msg, session_nullifier);
                vector::append(&mut msg, kyc_proof_hash);
                
                let pk = ed25519::new_unvalidated_public_key_from_bytes(*pk_bytes);
                let sig = ed25519::new_signature_from_bytes(*sig_bytes);
                
                if (ed25519::signature_verify_strict(&sig, &pk, msg)) {
                    ok = ok + 1;
                };
            };
            mut_i = mut_i + 1;
        };
        (ok as u8) >= set.quorum
    }
}

