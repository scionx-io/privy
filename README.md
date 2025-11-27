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

All API responses wrap data in `PrivyObject` instances that support both hash-like and method-based access:

```ruby
client = Privy::Client.new(app_id: 'your_app', app_secret: 'secret')
response = client.wallets.retrieve(wallet_id)

# Both access patterns work:
response.data['address']   # Hash-like access
response.data.address      # Method access (more Ruby-like)

# Full Enumerable support:
response.data.each { |k, v| puts "#{k}: #{v}" }
response.data.select { |k, v| v.present? }
```

PrivyObject provides convenient methods: `keys`, `values`, `key?`, `to_hash`, `to_json`, and full iteration support.

See [docs/PRIVY_OBJECT.md](docs/PRIVY_OBJECT.md) for complete documentation.

## Running Tests

```bash
bundle install
bundle exec rake test
```