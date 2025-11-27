# PrivyObject

## Overview

`PrivyObject` is a lightweight wrapper around Hash that provides both hash-like and method-based access to API response data. Inspired by Stripe's `StripeObject`, it makes working with API responses more ergonomic and Ruby-like.

## Features

- **Dual Access Patterns**: Both `obj['key']` and `obj.key` syntax
- **Enumerable Support**: Full iteration with `each`, `map`, `select`, `filter`, etc.
- **Clean Serialization**: Easy conversion with `to_hash`, `to_json`, `to_s`
- **Introspection**: Helper methods `keys`, `values`, `key?` for exploring data
- **Method Safety**: `respond_to?` and `method_missing` work correctly

## Basic Usage

### Accessing Data

API responses are automatically wrapped in PrivyObject:

```ruby
# Create client
client = Privy::Client.new(
  app_id: 'your_app_id',
  app_secret: 'your_app_secret'
)

# API call returns PrivyObject
response = client.wallets.retrieve(wallet_id)

# Hash-like access with strings
address = response.data['address']
chain = response.data['chain_type']

# Method-based access (more Ruby-like)
address = response.data.address
chain = response.data.chain_type

# Both string and symbol keys work
response.data['address']  # works
response.data[:address]   # also works
```

### Setting Values

```ruby
obj = Privy::Util::PrivyObject.new({})

# Bracket notation
obj['name'] = 'Alice'

# Method notation
obj.email = 'alice@example.com'

# Both set the same underlying hash
obj['name']  # => 'Alice'
obj.name     # => 'Alice'
```

## Enumerable Support

PrivyObject includes the Enumerable module, giving you full iteration capabilities:

```ruby
wallet = client.wallets.retrieve(wallet_id)

# Iterate over all attributes
wallet.data.each do |key, value|
  puts "#{key}: #{value}"
end

# Map to transform data
uppercase_keys = wallet.data.map { |k, v| [k.upcase, v] }

# Filter/select specific attributes
non_nil = wallet.data.select { |k, v| v.present? }

# Count attributes
wallet.data.count  # => 5

# Any other Enumerable method works
wallet.data.any? { |k, v| k == 'address' }
wallet.data.find { |k, v| v.nil? }
```

## Serialization

### to_hash / to_h

Convert back to a plain Ruby hash:

```ruby
obj = response.data
hash = obj.to_hash  # or obj.to_h

# Now it's a plain Hash
hash.class  # => Hash
```

### to_json

Convert to JSON string:

```ruby
obj = response.data
json = obj.to_json

# Pretty JSON for debugging
puts obj.to_json
# => {"address":"0x...","chain_type":"ethereum"}
```

### to_s

Returns JSON representation (same as to_json):

```ruby
puts response.data.to_s
# Outputs pretty JSON
```

## Introspection Methods

### keys

Get all attribute names:

```ruby
wallet = client.wallets.retrieve(wallet_id)
wallet.data.keys
# => ["id", "address", "chain_type", "created_at", "updated_at"]
```

### values

Get all attribute values:

```ruby
wallet.data.values
# => ["wlt_123...", "0x...", "ethereum", "2024-01-15T...", ...]
```

### key?

Check if an attribute exists:

```ruby
wallet.data.key?('address')     # => true
wallet.data.key?(:address)      # => true (symbol also works)
wallet.data.key?('nonexistent') # => false
```

## Working with Nested Data

### Nested Objects

Nested hashes remain as plain hashes (not auto-converted):

```ruby
response.data['metadata']
# => { "user_id" => "123", "source" => "app" }

# Access nested data
response.data['metadata']['user_id']  # => "123"
```

### Arrays

Arrays are preserved and can contain any data:

```ruby
# Balance endpoint returns array of balances
balance_response = client.wallets.balance(wallet_id)

balance_response.data['balances']
# => [{"chain"=>"arbitrum", "asset"=>"usdc", ...}, ...]

# Access array elements normally
balance_response.data['balances'].first
# => {"chain"=>"arbitrum", "asset"=>"usdc", ...}

# Iterate array
balance_response.data['balances'].each do |bal|
  puts "#{bal['asset']}: #{bal['raw_value']}"
end
```

## Comparison with Plain Hashes

**Before PrivyObject (plain hashes):**

```ruby
balance = response['data']['balances'][0]['display_values']['usd']
```

**After PrivyObject (method access):**

```ruby
# More readable, though balances is still an array
balance = response.data.balances.first['display_values']['usd']
```

**Best practice (mix both styles):**

```ruby
# Use method access for top-level, brackets for nested/arrays
balances = response.data.balances  # method access
first_balance = balances.first     # array access
usd = first_balance['display_values']['usd']  # hash access
```

## Design Philosophy

PrivyObject is intentionally simple and focused:

✅ **Does:**
- Provide convenient access to read-only response data
- Support Ruby's Enumerable patterns
- Serialize cleanly to Hash/JSON
- Work with both string and symbol keys

❌ **Doesn't:**
- Track changes or dirty state (responses are read-only)
- Manage complex update/save operations
- Auto-convert nested hashes (keeps them simple)
- Replace dedicated Resource classes

For resources that need create/update operations, use the dedicated Resource classes like `Privy::Resources::Wallet`.

## Debugging

### inspect

The inspect method shows the class name and all attributes:

```ruby
obj = Privy::Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
puts obj.inspect
# => #<PrivyObject:0x00007f8b1e8> {"name"=>"Alice", "age"=>30}
```

### Checking what methods are available

```ruby
obj.respond_to?(:address)  # => true (if 'address' key exists)
obj.respond_to?(:missing)  # => false

# Or just check keys
obj.keys  # => ['address', 'chain_type', ...]
```

## Examples

### Full wallet retrieval flow

```ruby
client = Privy::Client.new(
  app_id: ENV['PRIVY_APP_ID'],
  app_secret: ENV['PRIVY_APP_SECRET']
)

# Retrieve wallet
response = client.wallets.retrieve('wlt_...')

if response.success?
  wallet = response.data

  # Access with methods
  puts "Address: #{wallet.address}"
  puts "Chain: #{wallet.chain_type}"

  # Iterate attributes
  wallet.each do |key, value|
    puts "  #{key}: #{value}"
  end

  # Serialize
  wallet_hash = wallet.to_hash
  wallet_json = wallet.to_json
end
```

### Balance checking

```ruby
response = client.wallets.balance(
  'wlt_...',
  asset: 'usdc',
  chain: 'arbitrum'
)

if response.success?
  # response.data is PrivyObject
  balances = response.data.balances  # Access array

  balances.each do |balance|
    puts "#{balance['asset']} on #{balance['chain']}: #{balance['raw_value']}"
  end
end
```

## Migration from BridgedObject

PrivyObject is a drop-in replacement for the old BridgedObject:

```ruby
# Before (if you were using BridgedObject directly)
obj = Privy::Util::BridgedObject.new(data)

# After
obj = Privy::Util::PrivyObject.new(data)
```

For normal API usage through the client, no code changes needed - responses automatically use PrivyObject.