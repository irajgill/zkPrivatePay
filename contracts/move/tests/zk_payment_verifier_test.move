module zkprivatepay::zk_payment_verifier_test {
    use std::signer;
    use std::vector;
    use aptos_framework::ed25519;
    use zkprivatepay::zk_payment_verifier;

    #[test(creator = @0x42)]
    public fun test_quorum() {
        zk_payment_verifier::init(@zkprivatepay, 1);
        // Dummy pubkey and signature bytes (not valid), just testing storage/quorum logic path where 0 signatures fails.
        zk_payment_verifier::register_verifier(@zkprivatepay, @0x1, b"pubkey1");
        let ok = zk_payment_verifier::verify_attestation(@zkprivatepay, vector::singleton<address>(@0x1), vector::singleton<vector<u8>>(b"sig"), b"phash", b"topic");
        // ok likely false because signature won't verify; assert it is false
        assert!(!ok, 1);
    }
}
