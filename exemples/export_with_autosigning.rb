#!/usr/bin/env ruby
# frozen_string_literal: true

# This example demonstrates the simplified wallet export workflow using
# Privy's AuthorizationContext for automatic request signing.
#
# The user no longer needs to:
# - Manually generate authorization signatures
# - Construct the payload for signing
# - Handle JSON canonicalization
#
# Just configure the authorization key once and the gem handles everything!

require 'dotenv/load'
require_relative '../lib/privy'

# Configure Privy with your credentials
Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID']
  config.app_secret = ENV['PRIVY_APP_SECRET']
  # Set authorization private key for automatic signing
  config.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY']
end

# Create a client
client = Privy::Client.new

# Example wallet ID
wallet_id = ENV['WALLET_ID'] || 'your-wallet-id'

# Generate a recipient public key for HPKE encryption
# In production, you would have this from your key management system
require 'openssl'
require 'base64'

recipient_key = OpenSSL::PKey::EC.generate('prime256v1')
recipient_public_key_spki = recipient_key.public_to_der
recipient_public_key_b64 = Base64.strict_encode64(recipient_public_key_spki)

puts "Exporting wallet: #{wallet_id}"
puts "Using automatic signing with AuthorizationContext...\n\n"

# Export the wallet - signature is generated automatically!
response = client.wallets.export(
  wallet_id,
  encryption_type: 'HPKE',
  recipient_public_key: recipient_public_key_b64
)

if response.success?
  puts "✓ Export successful!"
  puts "\nEncrypted response:"
  puts "  Ciphertext: #{response.data.ciphertext[0..50]}..."
  puts "  Encapsulated Key: #{response.data.encapsulated_key[0..50]}..."

  # Now decrypt the response using the recipient private key
  require 'hpke'

  ciphertext = Base64.decode64(response.data.ciphertext)
  encapsulated_key = Base64.decode64(response.data.encapsulated_key)

  # Initialize HPKE with P-256, HKDF-SHA256, ChaCha20-Poly1305
  hpke = HPKE.new(0x0010, 0x0001, 0x0003)

  # Setup receiver context
  context = hpke.setup_base_r(encapsulated_key, recipient_key, '')

  # Decrypt
  decrypted_private_key = context.open('', ciphertext)

  puts "\n✓ Decryption successful!"
  puts "Wallet Private Key: #{decrypted_private_key}"

  # Verify the key works
  require 'eth'
  key = Eth::Key.new(priv: decrypted_private_key)
  puts "Wallet Address: #{key.address}"
else
  puts "✗ Export failed: #{response.error.message}"
end

puts "\n" + "="*60
puts "COMPARISON: Old vs New Approach"
puts "="*60
puts "\nOLD APPROACH (manual):"
puts "  1. Construct payload manually"
puts "  2. Canonicalize JSON (to_json_c14n)"
puts "  3. Load EC private key"
puts "  4. Sign payload with OpenSSL"
puts "  5. Base64 encode signature"
puts "  6. Pass signature to API call"
puts "\nNEW APPROACH (automatic):"
puts "  1. Configure authorization_private_key once"
puts "  2. Call client.wallets.export()"
puts "  → Everything else is automatic! ✨"
puts "="*60
