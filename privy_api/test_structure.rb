# frozen_string_literal: true

require 'bundler/setup'
require 'privy_api'

# Test basic functionality
PrivyApi.config do |c|
  c.app_id = 'test-app-id'
  c.app_secret = 'test-app-secret'
end

begin
  client = PrivyApi::Client.new(app_id: 'test', app_secret: 'test')
  puts "Privy API client created successfully"
  
  # Test that services are properly defined
  wallet_service = client.wallets
  puts "Wallet service available: #{wallet_service.class}"
  
  puts "Privy API wrapper structure is valid"
rescue => e
  puts "Error: #{e.message}"
end