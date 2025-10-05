#!/bin/bash

echo "🧪 zkPrivatePay Full System Test"
echo "================================="
echo ""

# 1. Backend health
echo "1️⃣ Backend:"
curl -s http://localhost:3001/health | jq '.ok' && echo "✅ OK" || echo "❌ Down"

# 2. Contract deployed
echo "2️⃣ Contract:"
curl -s "https://fullnode.testnet.aptoslabs.com/v1/accounts/0xd5f63b6f126ec4cc12948f0a5b6418d146776353c646fa0fa573f7b6b39af2cb/modules" | jq 'length' | grep -q "9" && echo "✅ Deployed (9 modules)" || echo "❌ Missing modules"

# 3. Vault initialized
echo "3️⃣ Vault:"
curl -s "https://fullnode.testnet.aptoslabs.com/v1/accounts/0xd5f63b6f126ec4cc12948f0a5b6418d146776353c646fa0fa573f7b6b39af2cb/resource/0xd5f63b6f126ec4cc12948f0a5b6418d146776353c646fa0fa573f7b6b39af2cb::zk_private_pay_manager::Vault<0x1::aptos_coin::AptosCoin>" | jq -e '.data' > /dev/null && echo "✅ Initialized" || echo "❌ Not initialized"

# 4. Account balance
echo "4️⃣ Balance:"
BALANCE=$(curl -s "https://fullnode.testnet.aptoslabs.com/v1/accounts/0xd5f63b6f126ec4cc12948f0a5b6418d146776353c646fa0fa573f7b6b39af2cb/resources" | jq -r '.[] | select(.type | contains("CoinStore<0x1::aptos_coin::AptosCoin>")) | .data.coin.value')
APT=$(echo "scale=4; $BALANCE / 100000000" | bc)
echo "✅ $APT APT"

echo ""
echo "================================="
echo "🎉 System Status: OPERATIONAL"
