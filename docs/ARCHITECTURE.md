# Architecture

**High-level flow:**

1. **Deposit**: User deposits USDC into `zkPrivatePayManager`. Coins are held in-module vault.
2. **Confidential Transfer**: Off-chain prover generates a Groth16/Plonk proof of a valid transfer over note commitments (amount hidden). ZK Verifier Network signs the `proof_hash` and public signals.
3. **On-chain acceptance**: `zkPaymentVerifier` verifies a quorum of ed25519 signatures on the `proof_hash`. `zkPrivatePayManager` updates state (nullifiers, new notes) and emits events.
4. **Withdrawal**: Proof attests that selected notes sum to requested amount; module releases USDC.
5. **Private FX**: User submits a private order commitment via `CLOBConnector`. Settlement is posted by the relayer with attested fills; vault settles deltas.
6. **Rollups**: `TreasuryRollupBatch` applies batched state deltas attested by the verifier network (90%+ gas savings target).
7. **Compliance**: `zkComplianceVerifier` verifies KYC proof attestations (Semaphore membership / Iden3 credential predicates) without revealing identity.

**Key components**

- **Circuits** (`circom`/`noir`): confidential payments; selective disclosure KYC; analytics aggregation.
- **Verifier Network** (off-chain): validates zk proofs; produces threshold ed25519 signatures.
- **Move Modules**: verify attestations, control vault, maintain commitments/nullifiers, CLOB bridging, rollups, escrow.
- **Gateway API**: manages proof jobs, relays txns, provides compliance oracle and analytics endpoints.
- **Frontend**: Aptos wallet integration; embedded proof generation when possible; encrypted local history.
- **Bot**: Telegram notifications.

