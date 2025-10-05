#!/bin/bash

cd ~/Desktop/zkprivatepay/backend

echo "🔍 Aptos Account Check"
echo "======================"
echo ""

# 1. Get address from private key
echo "1️⃣ Deriving address from private key..."
MY_ADDRESS=$(node << 'EOFNODE'
import { Account, Ed25519PrivateKey } from '@aptos-labs/ts-sdk';
import dotenv from 'dotenv';
dotenv.config();
const privateKeyHex = process.env.APTOS_PRIVATE_KEY?.replace('ed25519-priv-0x', '')?.replace('0x', '');
if (!privateKeyHex) { console.error('ERROR'); process.exit(1); }
const privateKey = new Ed25519PrivateKey(privateKeyHex);
const account = Account.fromPrivateKey({ privateKey });
console.log(account.accountAddress.toString());
EOFNODE
)

if [[ $MY_ADDRESS == "ERROR"* ]] || [[ -z "$MY_ADDRESS" ]]; then
  echo "❌ Could not derive address from APTOS_PRIVATE_KEY"
  echo "   Check your .env file"
  return 1
fi

# Extract just the address (remove warning)
MY_ADDRESS=$(echo "$MY_ADDRESS" | grep "^0x" | tail -1)

echo "✅ Address: $MY_ADDRESS"
echo ""

# 2. Check if account exists
echo "2️⃣ Checking if account exists on testnet..."
ACCOUNT_CHECK=$(curl -s "https://fullnode.testnet.aptoslabs.com/v1/accounts/$MY_ADDRESS")

if [[ $ACCOUNT_CHECK == *"account_not_found"* ]]; then
  echo "❌ Account NOT FOUND"
  echo ""
  echo "📝 ACTION REQUIRED:"
  echo "   1. Visit: https://aptoslabs.com/testnet-faucet"
  echo "   2. Paste: $MY_ADDRESS"
  echo "   3. Click 'Fund Account'"
  echo "   4. Wait 15 seconds"
  echo "   5. Run this script again"
  echo ""
  echo "🔗 Explorer: https://explorer.aptoslabs.com/account/$MY_ADDRESS?network=testnet"
  return 1
fi

echo "✅ Account exists"
SEQ_NUM=$(echo $ACCOUNT_CHECK | jq -r '.sequence_number')
echo "   Sequence number: $SEQ_NUM"
echo ""

# 3. Check balance
echo "3️⃣ Checking APT balance..."
RESOURCES=$(curl -s "https://fullnode.testnet.aptoslabs.com/v1/accounts/$MY_ADDRESS/resources")
BALANCE=$(echo $RESOURCES | jq -r '.[] | select(.type | contains("CoinStore<0x1::aptos_coin::AptosCoin>")) | .data.coin.value')

if [[ -z "$BALANCE" ]] || [[ "$BALANCE" == "null" ]]; then
  echo "❌ No APT balance found"
  echo ""
  echo "📝 ACTION REQUIRED:"
  echo "   Fund your account at: https://aptoslabs.com/testnet-faucet"
  echo "   Address: $MY_ADDRESS"
  return 1
fi

APT_BALANCE=$(echo "scale=4; $BALANCE / 100000000" | bc)
echo "✅ Balance: $APT_BALANCE APT"
echo "   ($BALANCE octas)"
echo ""

# 4. Summary
echo "======================"
echo "📊 SUMMARY"
echo "======================"
echo "Address: $MY_ADDRESS"
echo "Balance: $APT_BALANCE APT"
echo "Status: Ready ✅"
echo ""
echo "🔗 View on Explorer:"
echo "https://explorer.aptoslabs.com/account/$MY_ADDRESS?network=testnet"
echo ""
echo "🎉 Your Aptos account is ready!"
