#!/usr/bin/env bash
set -euo pipefail
aptos key generate --output-file zkpp.key
aptos account create --profile zkpp --private-key-file zkpp.key
