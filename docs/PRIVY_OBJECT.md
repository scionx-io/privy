# PrivyObject

## Overview

`PrivyObject` is a lightweight wrapper around Hash that provides both hash-like and method-based access to API response data. Inspired by Stripe's `StripeObject`, it makes working with API responses more ergonomic.

## Features

- **Dual Access**: Both `obj['key']` and `obj.key` syntax
- **Enumerable**: Supports `each`, `map`, `select`, etc.
- **Serialization**: `to_hash`, `to_json`, `to_s`
- **Introspection**: `keys`, `values`, `key?`

## Usage

### Basic Access

```ruby
# API responses are automatically wrapped in PrivyObject
response = client.wallets.balance(wallet_id)

# Hash-like access
balances = response.data['balances']

# Method access (more Ruby-like)
balances = response.data.balances

# Both work with string or symbol keys
response.data[:balances]
```

### Enumeration

```ruby
wallet = client.wallets.retrieve(wallet_id)

# Iterate over attributes
wallet.data.each do |key, value|
  puts "#{key}: #{value}"
end

# Use Enumerable methods
wallet.data.select { |k, v| v.present? }
```

### Serialization

```ruby
data = response.data

data.to_hash   # => { 'balances' => [...] }
data.to_json   # => "{\"balances\":[...]}"
data.to_s      # => Pretty JSON string
```

### Inspection

```ruby
data.keys      # => ['balances', 'metadata']
data.values    # => [[...], {...}]
data.key?('balances')  # => true
```

## Comparison with Plain Hashes

**Before (plain hash):**
```ruby
balance = response.parsed_response['data']['balances'][0]['display_values']['usd']
```

**After (PrivyObject):**
```ruby
balance = response.data.balances.first.display_values.usd
```

## Design Philosophy

`PrivyObject` is intentionally simple:
- No change tracking (read-only responses)
- No dirty state management
- No complex serialization for updates
- Just convenient access to response data

For resources that need mutations, use the dedicated Resource classes like `Privy::Resources::Wallet`.