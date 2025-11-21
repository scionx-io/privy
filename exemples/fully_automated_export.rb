#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================================================
# FULLY AUTOMATED WALLET EXPORT
# ============================================================================
#
# This example shows the SIMPLEST possible way to export a wallet using
# the Privy Ruby gem. NO manual cryptography, NO key management, NO hassle!
#
# What the gem does automatically:
#   ✓ Generates ephemeral HPKE keys in memory
#   ✓ Signs the request with your authorization key
#   ✓ Sends the export request to Privy API
#   ✓ Decrypts the response
#   ✓ Returns the plain wallet private key
#
# What you need to do:
#   1. Configure your credentials
#   2. Call client.wallets.export(wallet_id)
#   3. That's it!
#
# ============================================================================

require 'dotenv/load'
require_relative '../lib/privy'

# Step 1: Configure your Privy credentials ONCE
Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID']
  config.app_secret = ENV['PRIVY_APP_SECRET']
  config.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY']
end

# Step 2: Create a client
client = Privy::Client.new

# Step 3: Export the wallet (everything else is automatic!)
wallet_id = ENV['WALLET_ID'] || 'your-wallet-id'

puts "="*70
puts "FULLY AUTOMATED WALLET EXPORT"
puts "="*70
puts "\nExporting wallet: #{wallet_id}"
puts "Please wait...\n\n"

begin
  # This ONE line does everything:
  # - Generates HPKE keys
  # - Signs the request
  # - Calls Privy API
  # - Decrypts response
  # - Returns private key
  private_key = client.wallets.export(wallet_id)

  puts "✓ Export successful!"
  puts "\nWallet Private Key:"
  puts private_key
  puts ""

  # Verify the key works with eth gem
  require 'eth'
  key = Eth::Key.new(priv: private_key)
  puts "Wallet Address: #{key.address}"
  puts ""

  puts "="*70
  puts "WHAT JUST HAPPENED?"
  puts "="*70
  puts "1. Generated ephemeral HPKE key pair (P-256) in memory"
  puts "2. Constructed authorization signature automatically"
  puts "3. Sent export request to Privy API with public key"
  puts "4. Received HPKE-encrypted response"
  puts "5. Decrypted ciphertext with ephemeral private key"
  puts "6. Returned your wallet private key"
  puts ""
  puts "All cryptographic operations handled internally!"
  puts "No files written, no keys saved, no manual steps!"
  puts "="*70

rescue Privy::HpkeError => e
  puts "✗ Decryption failed: #{e.message}"
  puts "\nThis usually means:"
  puts "  • The HPKE encryption format changed"
  puts "  • Network corruption occurred"
  puts "  • The response was invalid"

rescue Privy::AuthorizationError => e
  puts "✗ Authorization failed: #{e.message}"
  puts "\nThis usually means:"
  puts "  • Your PRIVY_AUTHORIZATION_KEY is invalid"
  puts "  • The key doesn't have permission for this wallet"
  puts "  • The key format is incorrect"

rescue Privy::ApiError => e
  puts "✗ API error: #{e.message}"
  puts "\nCheck your credentials and wallet ID"

rescue StandardError => e
  puts "✗ Unexpected error: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n" + "="*70
puts "COMPARISON: Before vs After"
puts "="*70
puts "\nBEFORE (Manual - ~100 lines of code):"
puts "  require 'openssl'"
puts "  require 'base64'"
puts "  require 'json/canonicalization'"
puts "  require 'hpke'"
puts "  "
puts "  # Generate HPKE keys"
puts "  recipient_key = OpenSSL::PKey::EC.generate('prime256v1')"
puts "  public_key = Base64.strict_encode64(recipient_key.public_to_der)"
puts "  "
puts "  # Build signature payload"
puts "  payload = {"
puts "    'body' => {...},"
puts "    'headers' => {...},"
puts "    'method' => 'POST',"
puts "    'url' => '...',"
puts "    'version' => 1"
puts "  }"
puts "  "
puts "  # Sign manually"
puts "  serialized = payload.to_json_c14n"
puts "  key_pem = \"-----BEGIN PRIVATE KEY-----\\n#{key}\\n-----END...\""
puts "  ec_key = OpenSSL::PKey::EC.new(key_pem)"
puts "  signature = ec_key.sign(OpenSSL::Digest::SHA256.new, serialized)"
puts "  auth_sig = Base64.strict_encode64(signature)"
puts "  "
puts "  # Make request"
puts "  response = make_http_request(..., auth_sig)"
puts "  "
puts "  # Decrypt manually"
puts "  ciphertext = Base64.decode64(response['ciphertext'])"
puts "  encap_key = Base64.decode64(response['encapsulated_key'])"
puts "  hpke = HPKE.new(0x0010, 0x0001, 0x0003)"
puts "  context = hpke.setup_base_r(encap_key, recipient_key, '')"
puts "  decrypted = context.open('', ciphertext)"
puts ""
puts "AFTER (Automated - 3 lines of code):"
puts "  Privy.configure { |c| c.authorization_private_key = '...' }"
puts "  client = Privy::Client.new"
puts "  private_key = client.wallets.export(wallet_id)"
puts ""
puts "That's a 97% reduction in code! 🎉"
puts "="*70
