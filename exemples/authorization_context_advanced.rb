#!/usr/bin/env ruby
# frozen_string_literal: true

# This example demonstrates ADVANCED usage of AuthorizationContext
# for users who need fine-grained control over request signing.
#
# Use cases:
# - Multiple authorization keys
# - Per-request authorization context
# - Pre-computed signatures
# - Custom signing logic

require 'dotenv/load'
require_relative '../lib/privy'

# Setup client without global authorization key
client = Privy::Client.new(
  app_id: ENV['PRIVY_APP_ID'],
  app_secret: ENV['PRIVY_APP_SECRET']
)

wallet_id = ENV['WALLET_ID'] || 'your-wallet-id'

# Generate recipient keys
require 'openssl'
require 'base64'
recipient_key = OpenSSL::PKey::EC.generate('prime256v1')
recipient_public_key = Base64.strict_encode64(recipient_key.public_to_der)

puts "="*60
puts "EXAMPLE 1: Using Builder Pattern"
puts "="*60

# Build authorization context using builder pattern (Java-like API)
auth_context = Privy::AuthorizationContext.builder
  .add_authorization_private_key(ENV['PRIVY_AUTHORIZATION_KEY'])
  .build

response = client.wallets.export(
  wallet_id,
  recipient_public_key: recipient_public_key,
  authorization_context: auth_context
)

puts response.success? ? "✓ Success with builder pattern" : "✗ Failed: #{response.error}"

puts "\n" + "="*60
puts "EXAMPLE 2: Using Direct Initialization"
puts "="*60

# Create authorization context directly (Ruby-like API)
auth_context = Privy::AuthorizationContext.new(
  authorization_private_keys: [ENV['PRIVY_AUTHORIZATION_KEY']]
)

response = client.wallets.export(
  wallet_id,
  recipient_public_key: recipient_public_key,
  authorization_context: auth_context
)

puts response.success? ? "✓ Success with direct initialization" : "✗ Failed: #{response.error}"

puts "\n" + "="*60
puts "EXAMPLE 3: Using Pre-computed Signatures"
puts "="*60

# If you compute signatures elsewhere (e.g., in a KMS)
# you can pass them directly
pre_computed_signature = "your-pre-computed-base64-signature"

auth_context = Privy::AuthorizationContext.new(
  signatures: [pre_computed_signature]
)

# Note: This will fail unless you provide a real signature
# Just showing the API pattern here
puts "✓ AuthorizationContext created with pre-computed signature"

puts "\n" + "="*60
puts "EXAMPLE 4: Multiple Authorization Keys (Key Quorum)"
puts "="*60

# For wallets requiring multiple signatures
auth_context = Privy::AuthorizationContext.builder
  .add_authorization_private_key(ENV['PRIVY_AUTHORIZATION_KEY'])
  .add_authorization_private_key(ENV['PRIVY_AUTHORIZATION_KEY_2']) # If you have a second key
  .build

puts "✓ AuthorizationContext created with #{auth_context.authorization_private_keys.length} keys"

puts "\n" + "="*60
puts "EXAMPLE 5: Global vs Per-Request Authorization"
puts "="*60

# Global configuration (automatic for all requests)
Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID']
  config.app_secret = ENV['PRIVY_APP_SECRET']
  config.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY']
end

client_with_global = Privy::Client.new

# This uses the global authorization key automatically
response = client_with_global.wallets.export(
  wallet_id,
  recipient_public_key: recipient_public_key
)
puts "✓ Export with global authorization: #{response.success? ? 'Success' : 'Failed'}"

# This overrides with a different authorization context
different_auth_context = Privy::AuthorizationContext.new(
  authorization_private_keys: [ENV['PRIVY_AUTHORIZATION_KEY_OVERRIDE'] || ENV['PRIVY_AUTHORIZATION_KEY']]
)

response = client_with_global.wallets.export(
  wallet_id,
  recipient_public_key: recipient_public_key,
  authorization_context: different_auth_context
)
puts "✓ Export with override authorization: #{response.success? ? 'Success' : 'Failed'}"

puts "\n" + "="*60
puts "Summary"
puts "="*60
puts "AuthorizationContext provides flexible signing options:"
puts "  • Global configuration for all requests"
puts "  • Per-request authorization context"
puts "  • Builder pattern (Java-style) or direct init (Ruby-style)"
puts "  • Support for pre-computed signatures"
puts "  • Support for multiple keys (key quorums)"
puts "="*60
