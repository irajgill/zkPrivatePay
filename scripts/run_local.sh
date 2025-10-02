#!/usr/bin/env bash
set -euo pipefail
(cd backend && pnpm i && pnpm dev) &
(cd frontend && pnpm i && pnpm dev) &
wait
