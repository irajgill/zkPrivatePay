module zkprivatepay::i_clob {
    /// Generic interface for CLOB settlement relays.
    struct Fill has copy, drop, store {
        base_delta: u64,
        quote_delta: u64,
        fee: u64,
        taker: address,
        maker: address,
        order_commitment: vector<u8>
    }
}
