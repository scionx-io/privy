# Privy API Examples

This directory contains example code for testing all endpoints of the Privy gem.

## Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Set up your environment variables:
   Copy the `.env` file and add your actual credentials:
   ```bash
   cp .env .env.local
   # Edit .env.local with your actual credentials
   ```

## Running the Examples

You have two options to run the examples:

**Option 1: Export environment variables directly**
```bash
export PRIVY_APP_ID='your-actual-app-id'
export PRIVY_APP_SECRET='your-actual-app-secret'
# Optionally set a wallet ID for wallet-specific tests
export TEST_WALLET_ID='wallet-id-for-testing'

# Run the example
ruby test_all_endpoints.rb
```

**Option 2: Load from .env file using dotenv gem**
First, add dotenv to your Gemfile:
```ruby
# Add to your Gemfile
gem 'dotenv'
```
Then run with dotenv:
```bash
# Install dotenv
bundle add dotenv

# Load environment variables from .env file and run
ruby -e "require 'dotenv/load'; load 'test_all_endpoints.rb'"
```

## Available Examples

- `simple_example.rb`: Basic example showing how to list wallets
- `export_with_autosigning.rb`: Example showing wallet export with automatic request signing
- `fully_automated_export.rb`: Fully automated wallet export with all cryptography handled internally
- `authorization_context_advanced.rb`: Advanced usage of AuthorizationContext for fine-grained control
- `eth_sign7702_authorization.rb`: Example of signing EIP-7702 authorization structs