module zkprivatepay::events {
    use aptos_framework::account;
    use aptos_framework::event;

    struct VerifiedProofEvent has copy, drop, store {
        proof_hash: vector<u8>,
        topic: vector<u8>,
    }

    struct PaymentEvent has copy, drop, store {
        tx_id: vector<u8>,
        nullifiers: vector<vector<u8>>,
        commitments: vector<vector<u8>>,
        fee: u64,
    }

    struct RollupAppliedEvent has copy, drop, store {
        batch_id: u64,
        state_root: vector<u8>,
    }

    struct Events has key, store {  // Added 'store' ability
        verified_proof_handle: event::EventHandle<VerifiedProofEvent>,
        payment_handle: event::EventHandle<PaymentEvent>,
        rollup_handle: event::EventHandle<RollupAppliedEvent>,
    }

    public fun init(account: &signer): Events {
        Events {
            verified_proof_handle: account::new_event_handle<VerifiedProofEvent>(account),
            payment_handle: account::new_event_handle<PaymentEvent>(account),
            rollup_handle: account::new_event_handle<RollupAppliedEvent>(account),
        }
    }

    public fun emit_verified(e: &mut Events, proof_hash: vector<u8>, topic: vector<u8>) {
        event::emit_event(&mut e.verified_proof_handle, VerifiedProofEvent { proof_hash, topic });
    }

    public fun emit_payment(e: &mut Events, tx_id: vector<u8>, nullifiers: vector<vector<u8>>, commitments: vector<vector<u8>>, fee: u64) {
        event::emit_event(&mut e.payment_handle, PaymentEvent { tx_id, nullifiers, commitments, fee });
    }

    public fun emit_rollup(e: &mut Events, batch_id: u64, state_root: vector<u8>) {
        event::emit_event(&mut e.rollup_handle, RollupAppliedEvent { batch_id, state_root });
    }
}
