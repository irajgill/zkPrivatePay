# Threat Model (abridged)

**Assets**
- USDC vault funds
- Note commitments and nullifier set
- Compliance attestations
- User privacy (identities, amounts, graph)

**Trust Assumptions**
- Verifier network threshold is honest (e.g., 2/3 of N)
- Compliance oracles sign only valid proofs
- Aptos L1 safety & finality

**Adversaries**
- Malicious users attempting double-spend, withdraw without balance, linkage attacks.
- Malicious relayers; MEV observers; front-runners.
- Rogue verifier nodes or key compromise.

**Controls**
- Nonce/nullifier enforcement on-chain
- Threshold attestation for proof validity
- Rate limits and staking for relayers/verifiers
- Encrypted mempool via order commitments
- Auditable event logs (no sensitive data) with zk rollup state roots

**Open Risks**
- Off-chain proof verification centralization (mitigated by rotating keys & open membership)
- Metadata leakage through timing/graph (mitigated via batching & delays)
