#!/usr/bin/env ruby
# frozen_string_literal: true

# This example shows how to use the HpkeHelper to generate HPKE keys
# (if you need manual control over key generation)

require_relative '../lib/privy'

puts "="*70
puts "HPKE KEY GENERATION WITH PRIVY SDK"
puts "="*70
puts "\nGenerating ephemeral HPKE keys using Privy::HpkeHelper...\n\n"

# Generate HPKE keys using the helper
keys = Privy::HpkeHelper.generate_keys

puts "✓ Keys generated successfully!\n\n"

puts "Public Key (Base64 / SPKI format):"
puts keys[:public_key]
puts ""

puts "Private Key Type: #{keys[:private_key].class}"
puts "(Private key kept in memory, not shown for security)"
puts ""

puts "="*70
puts "USAGE NOTES"
puts "="*70
puts ""
puts "1. AUTOMATIC USAGE (recommended):"
puts "   Just call client.wallets.export(wallet_id)"
puts "   The SDK generates and manages keys automatically!"
puts ""
puts "2. MANUAL USAGE (advanced):"
puts "   keys = Privy::HpkeHelper.generate_keys"
puts "   response = client.wallets.export_raw("
puts "     wallet_id,"
puts "     recipient_public_key: keys[:public_key]"
puts "   )"
puts "   decrypted = Privy::HpkeHelper.decrypt("
puts "     ciphertext: response.data.ciphertext,"
puts "     encapsulated_key: response.data.encapsulated_key,"
puts "     private_key: keys[:private_key]"
puts "   )"
puts ""
puts "="*70
puts "KEY PROPERTIES"
puts "="*70
puts ""
puts "Algorithm Suite:"
puts "  • KEM: DHKEM(P-256, HKDF-SHA256)"
puts "  • KDF: HKDF-SHA256"
puts "  • AEAD: ChaCha20-Poly1305"
puts ""
puts "Security:"
puts "  • Ephemeral keys (forward secrecy)"
puts "  • Memory-only storage (never written to disk)"
puts "  • Authenticated encryption"
puts ""
puts "="*70

puts "\n💡 TIP: You don't need to run this script!"
puts "   The SDK handles everything automatically when you call:"
puts "   client.wallets.export(wallet_id)"
puts "="*70
