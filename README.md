# Privy API Integration

This repository contains an integration with Privy's wallet API, including:

## Structure

- `privy_api/` - Ruby gem for Privy API integration
- `exemples/` - Example usage files for testing the API endpoints

## Features

- Wallet management (create, retrieve, list)
- Balance checking
- Transaction history
- Proper object-oriented response handling

## Setup

1. Install dependencies:
   ```bash
   cd exemples
   bundle install
   ```

2. Configure your Privy credentials in the `.env` file

3. Run examples:
   ```bash
   ruby test_all_endpoints_comprehensive.rb
   ```