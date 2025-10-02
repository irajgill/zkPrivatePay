#!/usr/bin/env bash
set -euo pipefail
cd contracts/move
aptos move compile --named-addresses zkprivatepay=0x42
aptos move publish --named-addresses zkprivatepay=0x42 --profile mainnet --assume-yes
