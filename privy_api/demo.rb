# frozen_string_literal: true

require 'bundler/setup'
require 'privy_api'

# Example usage of the Privy API wrapper
puts "=== Privy API Ruby Wrapper Demo ===\n\n"

# Configure the API
PrivyApi.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID'] || 'your-app-id'
  config.app_secret = ENV['PRIVY_APP_SECRET'] || 'your-app-secret'
end

# Create a client
client = PrivyApi::Client.new(
  app_id: ENV['PRIVY_APP_ID'] || 'your-app-id',
  app_secret: ENV['PRIVY_APP_SECRET'] || 'your-app-secret'
)

puts "Client initialized successfully\n\n"

# Show available methods through the client
puts "Available wallet methods:"
puts "- client.wallets.list"
puts "- client.wallets.create(params, idempotency_key: 'optional')"
puts "- client.wallets.retrieve(wallet_id)"
puts "- client.wallets.balance(wallet_id)"
puts "- client.wallets.transactions(wallet_id)"
puts "\n"

# Show resource-level methods
puts "Available resource methods:"
puts "- PrivyApi::Resources::Wallet.list"
puts "- PrivyApi::Resources::Wallet.create(params)"
puts "- PrivyApi::Resources::Wallet.retrieve(wallet_id)"
puts "- PrivyApi::Resources::Wallet.balance(wallet_id)"
puts "- PrivyApi::Resources::Wallet.transactions(wallet_id)"
puts "\n"

puts "For actual API calls, provide real credentials via environment variables:"
puts "PRIVY_APP_ID and PRIVY_APP_SECRET"