#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
circom payment.circom --r1cs --wasm --sym -o build
circom kyc_selective_disclosure.circom --r1cs --wasm --sym -o build

# Trusted setup (Groth16) - dev only
snarkjs groth16 setup build/payment.r1cs powersOfTau28_hez_final_18.ptau build/payment_0000.zkey
snarkjs zkey contribute build/payment_0000.zkey build/payment_final.zkey -e="dev"
snarkjs zkey export verificationkey build/payment_final.zkey build/payment_vkey.json

snarkjs groth16 setup build/kyc_selective_disclosure.r1cs powersOfTau28_hez_final_18.ptau build/kyc_0000.zkey
snarkjs zkey contribute build/kyc_0000.zkey build/kyc_final.zkey -e="dev"
snarkjs zkey export verificationkey build/kyc_final.zkey build/kyc_vkey.json
