module zkprivatepay::i_stablecoin {
    use aptos_framework::coin;

    /// Marker trait: any stablecoin type must implement Coin.
    /// No acquires needed - coin::transfer handles CoinStore access internally
    public fun transfer<T>(from: &signer, to: address, amount: u64) {
        coin::transfer<T>(from, to, amount);
    }
}
