#!/bin/bash

set -e  # Exit on error

echo "🚀 zkPrivatePay Contract Deployment"
echo "===================================="
echo ""

CONTRACT_ADDR="0xd5f63b6f126ec4cc12948f0a5b6418d146776353c646fa0fa573f7b6b39af2cb"
TESTNET_URL="https://fullnode.testnet.aptoslabs.com/v1"
PRIVATE_KEY="0x6075de882efde8007ab31e15fbdbf04a1db5c8802af446dacd2fc6e8c89962ea"

# 1. Check current status
echo "1️⃣ Checking deployment status..."
MODULE_COUNT=$(curl -s "$TESTNET_URL/accounts/$CONTRACT_ADDR/modules" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
echo "   Current modules: $MODULE_COUNT"
echo ""

if [ "$MODULE_COUNT" -gt 0 ]; then
  echo "⚠️  Contract already deployed!"
  echo "   Modules found:"
  curl -s "$TESTNET_URL/accounts/$CONTRACT_ADDR/modules" | jq -r '.[].abi.name' | head -5
  echo ""
  read -p "Republish anyway? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping publish..."
    SKIP_PUBLISH=true
  fi
fi

# 2. Compile
if [ "$SKIP_PUBLISH" != "true" ]; then
  echo "2️⃣ Compiling contracts..."
  aptos move compile --named-addresses zkprivatepay=$CONTRACT_ADDR
  echo "✅ Compilation successful"
  echo ""
  
  # 3. Publish
  echo "3️⃣ Publishing to testnet..."
  echo "   This may take 30-60 seconds..."
  aptos move publish \
    --named-addresses zkprivatepay=$CONTRACT_ADDR \
    --url $TESTNET_URL \
    --private-key $PRIVATE_KEY \
    --assume-yes
  
  if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
  else
    echo "❌ Deployment failed"
    exit 1
  fi
  echo ""
  
  # Wait for finalization
  echo "⏳ Waiting 10 seconds for transaction finalization..."
  sleep 10
fi

# 4. Verify
echo "4️⃣ Verifying deployment..."
MODULES=$(curl -s "$TESTNET_URL/accounts/$CONTRACT_ADDR/modules" | jq -r '.[].abi.name' 2>/dev/null)
if [ -z "$MODULES" ]; then
  echo "❌ No modules found!"
  exit 1
else
  echo "✅ Deployed modules:"
  echo "$MODULES"
fi
echo ""

# 5. Initialize
echo "5️⃣ Initializing manager..."
aptos move run \
  --function-id $CONTRACT_ADDR::zk_private_pay_manager::initialize \
  --url $TESTNET_URL \
  --private-key $PRIVATE_KEY \
  --assume-yes

EXIT_CODE=$?
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ Manager initialized successfully!"
elif [ $EXIT_CODE -eq 7 ]; then
  echo "⚠️  Manager already initialized (this is OK)"
else
  echo "⚠️  Initialization returned code: $EXIT_CODE"
fi

echo ""
echo "===================================="
echo "🎉 Deployment Complete!"
echo ""
echo "🔗 View on Explorer:"
echo "https://explorer.aptoslabs.com/account/$CONTRACT_ADDR?network=testnet"
echo ""
echo "📋 Transaction History:"
echo "https://explorer.aptoslabs.com/account/$CONTRACT_ADDR/transactions?network=testnet"
echo ""
echo "📦 Modules:"
echo "https://explorer.aptoslabs.com/account/$CONTRACT_ADDR/modules?network=testnet"
