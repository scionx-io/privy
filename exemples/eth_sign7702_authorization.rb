#!/usr/bin/env ruby
# frozen_string_literal: true

# This example demonstrates how to use the eth_sign7702Authorization method
# to sign an EIP-7702 authorization struct using a Privy wallet's private key.
#
# EIP-7702 allows EOAs (Externally Owned Accounts) to temporarily delegate
# code execution to a smart contract, enabling account abstraction while
# maintaining the security model of existing EOAs.

require 'dotenv/load'
require_relative '../lib/privy'

# Configure Privy with your credentials
Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID']
  config.app_secret = ENV['PRIVY_APP_SECRET']
  # Set authorization private key for automatic signing (if required by your wallet)
  config.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY'] if ENV['PRIVY_AUTHORIZATION_KEY']
end

# Create a client
client = Privy::Client.new

# Example wallet ID
wallet_id = ENV['WALLET_ID'] || 'your-wallet-id'

# Example EIP-7702 authorization parameters
contract_address = '0x1234567890abcdef1234567890abcdef12345678'  # The contract to delegate to
chain_id = 1  # Ethereum mainnet
nonce = 0  # Authorization nonce (defaults to 0 if not provided)

puts "="*70
puts "EIP-7702 AUTHORIZATION SIGNING EXAMPLE"
puts "="*70
puts "\nParameters:"
puts "  Wallet ID: #{wallet_id}"
puts "  Contract Address: #{contract_address}"
puts "  Chain ID: #{chain_id}"
puts "  Nonce: #{nonce}"
puts "\nSigning EIP-7702 authorization...\n\n"

begin
  # Sign the EIP-7702 authorization struct
  response = client.wallets.eth_sign7702Authorization(
    wallet_id,
    contract_address,
    chain_id,
    nonce: nonce
  )

  if response.success?
    auth_data = response.data['data']['authorization']

    puts "✓ EIP-7702 authorization signed successfully!"
    puts ""
    puts "Authorization Details:"
    puts "  Contract: #{auth_data['contract']}"
    puts "  Chain ID: #{auth_data['chain_id']}"
    puts "  Nonce: #{auth_data['nonce']}"
    puts "  R component: #{auth_data['r']}"
    puts "  S component: #{auth_data['s']}"
    puts "  Y parity: #{auth_data['y_parity']}"
    puts ""
    puts "The signed authorization can now be used for EIP-7702 transactions"
    puts "on the specified chain with the specified contract delegation."
  else
    puts "✗ Failed to sign EIP-7702 authorization: #{response.error.message}"
  end

  # Example with authorization signature provided manually (if needed)
  puts "\n" + "-"*50
  puts "Alternative: Using explicit authorization signature"
  puts "-"*50

  auth_signature = ENV['PRIVY_AUTHORIZATION_SIGNATURE']  # If you have a pre-computed signature

  if auth_signature
    response = client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract_address,
      chain_id,
      nonce: nonce,
      authorization_signature: auth_signature
    )

    if response.success?
      puts "✓ EIP-7702 authorization signed successfully with explicit signature!"
      auth_data = response.data['data']['authorization']
      puts "Signature components: r=#{auth_data['r'][0..20]}..., s=#{auth_data['s'][0..20]}..."
    else
      puts "✗ Failed with explicit signature: #{response.error.message}"
    end
  else
    puts "No authorization signature provided in environment variables."
    puts "Set PRIVY_AUTHORIZATION_SIGNATURE to test this alternative."
  end

rescue StandardError => e
  puts "✗ Unexpected error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n" + "="*70
puts "ABOUT EIP-7702"
puts "="*70
puts "\nEIP-7702 enables EOAs to temporarily delegate to smart contracts by:"
puts "  • Setting the delegated code on an EOA at transaction time"
puts "  • Allowing the EOA to execute code from the delegated contract"
puts "  • Maintaining the EOA's identity and security model"
puts ""
puts "The authorization signature allows the EOA to approve delegation"
puts "to a specific contract for a specific chain and nonce."
puts "="*70