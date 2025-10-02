# Security Audit Checklist (templates)

- [ ] Move modules: reentrancy, resource leakage, access control, event correctness
- [ ] Signature domain separation, replay protection (salt/chain_id/expiry)
- [ ] Nullifier uniqueness and mapping
- [ ] Vault accounting invariants (Coin<T> supply conserved)
- [ ] Rollup batch apply/rollback logic
- [ ] CLOB settlement price/qty bounds, fee accounting
- [ ] Compliance verifier: key rotation, threshold logic
- [ ] Frontend: wallet permissions, CSP, build integrity
- [ ] Backend: secret management, rate limiting, DoS resistance, input validation
- [ ] Circuits: constraint coverage, soundness, test vectors, toxic waste handling
- [ ] Ops: backups, observability, alerting, incident response
