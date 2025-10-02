# Circuits

This folder contains Circom and Noir circuits for zkPrivatePay.

- `circom/payment.circom`: Confidential transfer with note commitments, nullifiers, Merkle inclusion and value conservation.
- `circom/kyc_selective_disclosure.circom`: KYC membership & predicate proofs for compliance without revealing identity.
- Noir equivalents provided in `noir/` for teams preferring Noir.

## Build (Circom)

```bash
cd circuits/circom
./build.sh  # requires circom and snarkjs
```

Outputs are placed in `build/` (R1CS, WASM, zkeys, verification keys).
