require 'bundler/setup'
require 'dotenv/load'  # Load environment variables from .env file
require 'privy'

# Configure the API credentials
Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID'] || 'your-app-id'
  config.app_secret = ENV['PRIVY_APP_SECRET'] || 'your-app-secret'
end

# Initialize the client
client = Privy::Client.new

# Example of how to use the API
puts "Listing wallets..."
response = client.wallets.list

if response.success?
  puts "Successfully retrieved wallets!"
  puts "Status code: #{response.status_code}"

  wallets_collection = response.data
  if wallets_collection && wallets_collection.is_a?(Privy::ListObject)
    puts "Number of wallets: #{wallets_collection.length}"

    # Print first few wallets if available
    wallets_collection.first(3).each_with_index do |wallet, index|
      puts "Wallet #{index + 1}: ID=#{wallet['id']}, Type=#{wallet['type']}" if wallet
    end

    # Example of exporting a wallet (if you have a wallet ID)
    if wallets_collection.length > 0 && ENV['TEST_WALLET_ID']
      puts "\nAttempting to export wallet..."
      export_response = client.wallets.export(
        ENV['TEST_WALLET_ID'],
        encryption_type: 'HPKE',
        recipient_public_key: 'your-base64-encoded-public-key-here'
      )

      if export_response.success?
        puts "Successfully exported wallet!"
        puts "Encryption type: #{export_response.data['encryption_type']}"
        puts "Ciphertext: #{export_response.data['ciphertext']}"
        puts "Encapsulated key: #{export_response.data['encapsulated_key']}"
      else
        puts "Export error: #{export_response.error.message}"
      end
    end
  end
else
  puts "Error: #{response.error.message}"
end