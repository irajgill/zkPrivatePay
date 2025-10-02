module zkprivatepay::zk_payment_verifier {
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::ed25519;
    use aptos_std::table::{Self as table, Table};

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_BAD_SIG: u64 = 2;

    struct VerifierSet has key {
        quorum: u8,
        keys: Table<address, vector<u8>>
    }

    public fun init(account: &signer, quorum: u8) {
        move_to(account, VerifierSet { quorum, keys: table::new<address, vector<u8>>() });
    }

    public fun register_verifier(account: &signer, attester: address, pubkey: vector<u8>) acquires VerifierSet {
        let addr = signer::address_of(account);
        assert!(exists<VerifierSet>(addr), error::invalid_argument(E_NOT_AUTHORIZED));
        let vs = borrow_global_mut<VerifierSet>(addr);
        table::add(&mut vs.keys, attester, pubkey);
    }

    public fun set_quorum(account: &signer, quorum: u8) acquires VerifierSet {
        let vs = borrow_global_mut<VerifierSet>(signer::address_of(account));
        vs.quorum = quorum;
    }

    public fun verify_attestation(
        account: &signer,
        attesters: vector<address>,
        sigs: vector<vector<u8>>,
        proof_hash: vector<u8>,
        topic: vector<u8>
    ): bool acquires VerifierSet {
        let addr = signer::address_of(account);
        let vs = borrow_global<VerifierSet>(addr);
        let n = vector::length(&attesters);
        let ok: u64 = 0;
        let mut_i = 0;
        while (mut_i < n) {
            let who = *vector::borrow(&attesters, mut_i);
            let sig_bytes = vector::borrow(&sigs, mut_i);
            if (table::contains(&vs.keys, who)) {
                let pk_bytes = table::borrow(&vs.keys, who);
                let msg = vector::empty<u8>();
                vector::append(&mut msg, b"zkPP:attest:");
                vector::append(&mut msg, topic);
                vector::append(&mut msg, proof_hash);
                
                let pk = ed25519::new_unvalidated_public_key_from_bytes(*pk_bytes);
                let sig = ed25519::new_signature_from_bytes(*sig_bytes);
                
                if (ed25519::signature_verify_strict(&sig, &pk, msg)) {
                    ok = ok + 1;
                };
            };
            mut_i = mut_i + 1;
        };
        (ok as u8) >= vs.quorum
    }
}

