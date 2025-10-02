#!/usr/bin/env bash
set -euo pipefail
# Requires aptos CLI configured with a profile that holds 0x42 account (for demo)
cd contracts/move
aptos move compile --named-addresses zkprivatepay=0x42
aptos move publish --named-addresses zkprivatepay=0x42 --profile default --assume-yes
