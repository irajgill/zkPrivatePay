# zkPrivatePay

A privacy-preserving cross-border payment and remittance platform on **Aptos** using **zero-knowledge proofs** (zk-SNARKs) for confidential, compliant stablecoin transfers and private on-chain FX trading.

> **Design note:** Aptos Move currently does not expose pairing-friendly precompiles required for on-chain Groth16 verification. This implementation verifies zk-proofs via **attested verification** (a quorum of zk verifier nodes checks proofs off-chain and signs a commitment). Move modules verify the attestations (ed25519), enabling efficient and parallel on-chain verification while preserving full proof auditability.

## Monorepo Layout

```
zkprivatepay/
├─ contracts/move/                 # Aptos Move modules
├─ circuits/                       # Circom & Noir circuits + docs
├─ backend/                        # Transaction Gateway API + Compliance Oracle (TypeScript)
├─ frontend/                       # React web app
├─ telegram-bot/                   # Telegraf bot for notifications
├─ tests/                          # Unit & integration tests
├─ deployment/                     # Docker, K8s, Terraform (samples)
├─ scripts/                        # Helper scripts (deploy, keys, run local)
└─ docs/                           # Architecture, threat model, compliance, audits
```

## Quick Start (local dev)

1. **Install tools**
   - Node.js >= 20, pnpm or yarn
   - Rust (for Noir optional)
   - `circom`, `snarkjs`
   - Aptos CLI
   - Docker (for Postgres + Redis)

2. **Clone & bootstrap**

```bash
pnpm -v || npm i -g pnpm
cd backend && pnpm i && cd ..
cd frontend && pnpm i && cd ..
```

3. **Run infrastructure**

```bash
cd backend/docker
docker compose up -d  # postgres, redis, api
```

4. **Compile circuits (optional for first run)**
See `circuits/README.md`.

5. **Deploy Move contracts (testnet)**

```bash
./scripts/deploy_aptos_testnet.sh
```

6. **Start frontend**

```bash
cd frontend && pnpm dev
```
