# Privy API Examples

This directory contains example code for testing all endpoints of the Privy API gem.

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

- `test_all_endpoints.rb`: Tests all Privy API endpoints (list, create, retrieve, balance, transactions)
- `test_all_endpoints_comprehensive.rb`: More detailed testing with proper object handling
- `simple_example.rb`: Basic example showing how to list wallets