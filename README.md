# Privy Ruby Client

A Ruby client for the Privy API, providing wallet management functionality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'privy', path: '.'
```

Or install manually:

```bash
gem install privy
```

## Usage

```ruby
require 'privy'

Privy.configure do |config|
  config.app_id = 'your-app-id'
  config.app_secret = 'your-app-secret'
end

client = Privy::Client.new
response = client.wallets.list
```

## Features

- Wallet management (list, create, retrieve)
- Balance checking
- Transaction history
- Object-oriented response handling

## Running Tests

```bash
bundle install
bundle exec rake test
```