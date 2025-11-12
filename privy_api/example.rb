#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/privy_api'

# Configure the Privy API
PrivyApi.configure do |config|
  config.app_id = 'your-app-id'
  config.app_secret = 'your-app-secret'
end

# Create a client instance
client = PrivyApi::Client.new

# Example: List wallets
puts 'Listing wallets...'
response = client.wallets.list
if response.success?
  puts "Found #{response.data.length} wallets"
  response.data.each do |wallet|
    puts "Wallet: #{wallet}"
  end
else
  puts "Error: #{response.error.message}"
end

# Example: Create a wallet
puts "\nCreating a new wallet..."
create_response = client.wallets.create({ chain: 'ethereum' }, idempotency_key: 'unique-key-123')
if create_response.success?
  puts "Wallet created: #{create_response.data}"
else
  puts "Error creating wallet: #{create_response.error.message}"
end

# Using the wallet resource directly
puts "\nUsing wallet resource directly..."
wallet_list = PrivyApi::Resources::Wallet.list
if wallet_list.success?
  puts "Wallet count: #{wallet_list.data.length}"
end