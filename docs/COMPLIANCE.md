# Compliance Overview

- **KYC/AML** via selective disclosure:
  - Prove membership in `KYC_APPROVED` identity set (Semaphore-style group root).
  - Optionally prove `country ∈ allowed_countries` and `sanctioned == false` via Merkle predicate circuits.
  - No PII revealed on-chain. Auditors can request disclosure off-chain via user consent.

- **Travel Rule**:
  - Off-chain message set exchanged between VASPs; proof that Travel Rule envelope was formed and signed is attested.

- **Record Keeping**:
  - Events include proof and attestation hashes. Off-chain store keeps encrypted audit bundle.

- **Sanctions**:
  - Oracle rotates blocklists; proofs must attest to non-membership of blocked sets.

