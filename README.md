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

## Response Objects

All API responses are wrapped in `PrivyObject` instances that support both hash-like and method-based access:

```ruby
response = client.wallets.retrieve(wallet_id)

# Both work:
response.data['address']
response.data.address

# Enumerable support:
response.data.each { |k, v| puts "#{k}: #{v}" }
```

See [docs/PRIVY_OBJECT.md](docs/PRIVY_OBJECT.md) for details.

## Running Tests

```bash
bundle install
bundle exec rake test
```