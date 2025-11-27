# PrivyObject Refactoring Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename BridgedObject to PrivyObject and add Stripe-style API response object design with better serialization and enumeration support.

**Architecture:** Replace the confusingly-named BridgedObject (conflicts with Bridge API) with PrivyObject. Model after Stripe's StripeObject design: hash storage, dynamic method access, Enumerable support, and clean serialization. Keep implementation simple (no change tracking since Privy is mostly read-only).

**Tech Stack:** Ruby 3.x, HTTParty for API calls, OpenSSL for cryptography

---

## Task 1: Rename BridgedObject to PrivyObject

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb:60-118`

**Step 1: Write test for PrivyObject basic functionality**

Create: `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/privy_object_test.rb`

```ruby
# frozen_string_literal: true

require 'test_helper'

module Privy
  class PrivyObjectTest < Minitest::Test
    def test_initialize_with_attributes
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      assert_equal 'Alice', obj['name']
      assert_equal 30, obj['age']
    end

    def test_bracket_access
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      assert_equal 100, obj['balance']
    end

    def test_method_access_string_key
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      assert_equal 100, obj.balance
    end

    def test_method_access_symbol_key
      obj = Util::PrivyObject.new({ balance: 200 })
      assert_equal 200, obj.balance
    end

    def test_setter_via_bracket
      obj = Util::PrivyObject.new({})
      obj['name'] = 'Bob'
      assert_equal 'Bob', obj['name']
    end

    def test_setter_via_method
      obj = Util::PrivyObject.new({})
      obj.name = 'Charlie'
      assert_equal 'Charlie', obj.name
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: FAIL with "uninitialized constant Privy::Util::PrivyObject"

**Step 3: Rename BridgedObject class to PrivyObject**

Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb`

Find the BridgedObject class definition (around line 60) and rename it:

```ruby
    # A simple class to allow hash-like and method-based access to API response objects
    class PrivyObject
      def initialize(attributes = {})
        @attributes = attributes
      end

      def [](key)
        @attributes[key]
      end

      def []=(key, value)
        @attributes[key] = value
      end

      def method_missing(method_name, *args, &block)
        method_name_str = method_name.to_s
        if method_name_str.end_with?('=')
          # Setter
          attr_name = method_name_str[0...-1]
          @attributes[attr_name] = args.first
        elsif @attributes.key?(method_name_str)
          # Getter
          @attributes[method_name_str]
        elsif @attributes.key?(method_name_str.to_sym)
          # Getter with symbol key
          @attributes[method_name_str.to_sym]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @attributes.key?(method_name.to_s) || @attributes.key?(method_name.to_sym) || super
      end

      def to_h
        @attributes
      end

      def to_json(*args)
        @attributes.to_json(*args)
      end

      def inspect
        "#<PrivyObject:0x#{object_id.to_s(16)} #{@attributes.inspect}>"
      end

      private

      def convert_value(value)
        case value
        when Hash
          PrivyObject.new(value)
        when Array
          value.map { |v| convert_value(v) }
        else
          value
        end
      end
    end
```

**Step 4: Update convert_to_bridged_object method name**

In same file `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb`, rename the method (around line 10):

```ruby
      # Convert API response data to PrivyObject for easy access
      def convert_to_privy_object(data)
        if data.is_a?(Hash)
          PrivyObject.new(data)
        elsif data.is_a?(Array)
          data.map { |item| convert_to_privy_object(item) }
        else
          data
        end
      end
```

**Step 5: Run test to verify it passes**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: PASS - all 6 tests passing

**Step 6: Commit**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add lib/privy/util.rb test/privy/privy_object_test.rb
git commit -m "refactor: rename BridgedObject to PrivyObject

- Rename BridgedObject class to PrivyObject
- Rename convert_to_bridged_object to convert_to_privy_object
- Update inspect method to show PrivyObject class name
- Add comprehensive test coverage for basic functionality"
```

---

## Task 2: Add Stripe-Style Helper Methods

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb:60-118`
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/privy_object_test.rb`

**Step 1: Write tests for new helper methods**

Add to `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/privy_object_test.rb`:

```ruby
    def test_to_hash
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      hash = obj.to_hash

      assert_instance_of Hash, hash
      assert_equal 'Alice', hash['name']
      assert_equal 30, hash['age']
    end

    def test_to_json
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      json = obj.to_json

      assert_instance_of String, json
      assert_includes json, '"balance"'
      assert_includes json, '100'
    end

    def test_keys
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      keys = obj.keys

      assert_equal ['name', 'age'].sort, keys.sort
    end

    def test_values
      obj = Util::PrivyObject.new({ 'name' => 'Alice', 'age' => 30 })
      values = obj.values

      assert_includes values, 'Alice'
      assert_includes values, 30
    end

    def test_inspect_format
      obj = Util::PrivyObject.new({ 'name' => 'Alice' })
      inspected = obj.inspect

      assert_match(/PrivyObject:0x[0-9a-f]+/, inspected)
      assert_includes inspected, 'name'
      assert_includes inspected, 'Alice'
    end

    def test_to_s_returns_json
      obj = Util::PrivyObject.new({ 'balance' => 100 })
      string = obj.to_s

      assert_instance_of String, string
      assert_includes string, 'balance'
    end
```

**Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: FAIL - "undefined method `keys'" and similar errors

**Step 3: Add helper methods to PrivyObject**

Modify `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb` PrivyObject class:

Add these methods after the existing methods (before the `private` keyword):

```ruby
      # Return the underlying hash
      alias to_hash to_h

      # Get all keys from the attributes hash
      def keys
        @attributes.keys
      end

      # Get all values from the attributes hash
      def values
        @attributes.values
      end

      # String representation returns JSON for readability
      def to_s
        to_json
      end

      # Check if a key exists
      def key?(key)
        @attributes.key?(key) || @attributes.key?(key.to_s) || @attributes.key?(key.to_sym)
      end
```

**Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: PASS - all 12 tests passing

**Step 5: Commit**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add lib/privy/util.rb test/privy/privy_object_test.rb
git commit -m "feat: add Stripe-style helper methods to PrivyObject

- Add keys(), values() methods for hash-like iteration
- Add to_s() that returns JSON for better readability
- Add key?() for checking attribute existence
- Add alias to_hash for to_h
- Add comprehensive tests for all new methods"
```

---

## Task 3: Add Enumerable Support

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb:60`
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/privy_object_test.rb`

**Step 1: Write tests for Enumerable functionality**

Add to `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/privy_object_test.rb`:

```ruby
    def test_enumerable_each
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })
      result = {}

      obj.each { |k, v| result[k] = v }

      assert_equal({ 'a' => 1, 'b' => 2, 'c' => 3 }, result)
    end

    def test_enumerable_map
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2 })
      result = obj.map { |k, v| [k.upcase, v * 2] }

      assert_equal([['A', 2], ['B', 4]], result)
    end

    def test_enumerable_select
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })
      result = obj.select { |_k, v| v > 1 }

      assert_equal({ 'b' => 2, 'c' => 3 }, result.to_h)
    end

    def test_enumerable_count
      obj = Util::PrivyObject.new({ 'a' => 1, 'b' => 2, 'c' => 3 })

      assert_equal 3, obj.count
    end
```

**Step 2: Run tests to verify they fail**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: FAIL - "undefined method `map'" or "undefined method `each'"

**Step 3: Include Enumerable and implement each**

Modify `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/util.rb` PrivyObject class:

```ruby
    class PrivyObject
      include Enumerable

      def initialize(attributes = {})
        @attributes = attributes
      end

      # ... existing methods ...

      # Enumerable support - iterate over key-value pairs
      def each(&block)
        @attributes.each(&block)
      end
```

**Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/privy_object_test.rb
```

Expected: PASS - all 16 tests passing

**Step 5: Commit**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add lib/privy/util.rb test/privy/privy_object_test.rb
git commit -m "feat: add Enumerable support to PrivyObject

- Include Enumerable module
- Implement each() to iterate over key-value pairs
- Enables map, select, filter, count, and other Enumerable methods
- Add tests for enumerable functionality"
```

---

## Task 4: Update Client to Use PrivyObject

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/client.rb:102`
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/client_test.rb` (if exists)

**Step 1: Check current state of client.rb**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
grep -n "convert_to_bridged_object\|convert_to_privy_object" lib/privy/client.rb
```

Expected: Shows whether the method is currently being called or not

**Step 2: Update client.rb to use convert_to_privy_object**

Modify `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/client.rb` around line 97-105:

```ruby
    def handle_response(response)
      status = response.code
      success = (200..299).cover?(status)

      raw_data = success ? response.parsed_response : nil
      data = raw_data ? Util.convert_to_privy_object(raw_data) : nil
      error = success ? nil : build_error(status, response)

      Response.new(status, data, error)
    end
```

**Step 3: Write integration test for balance endpoint**

Create or modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/test/privy/wallet_service_test.rb`

```ruby
# frozen_string_literal: true

require 'test_helper'

module Privy
  module Services
    class WalletServiceTest < Minitest::Test
      def setup
        @client = Privy::Client.new(
          app_id: 'test_app_id',
          app_secret: 'test_app_secret'
        )
        @service = @client.wallets
      end

      def test_balance_returns_privy_object_with_balances
        # Mock the HTTP response
        mock_response = {
          'balances' => [
            {
              'chain' => 'arbitrum',
              'asset' => 'usdc',
              'raw_value' => '1000000',
              'raw_value_decimals' => 6,
              'display_values' => {
                'usdc' => '1.0',
                'usd' => '1.00'
              }
            }
          ]
        }

        # Stub the request method to return mock response
        response = OpenStruct.new(
          code: 200,
          parsed_response: mock_response
        )

        @client.stub :request, Privy::Client::Response.new(200, Util::PrivyObject.new(mock_response), nil) do
          result = @service.balance('wallet_123')

          # Should return Response with PrivyObject data
          assert result.success?
          assert_instance_of Util::PrivyObject, result.data
          assert result.data.key?('balances')
          assert_instance_of Array, result.data['balances']
        end
      end
    end
  end
end
```

**Step 4: Run integration test**

Run:
```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
ruby test/privy/wallet_service_test.rb
```

Expected: PASS - integration test confirms PrivyObject is used

**Step 5: Test with Rails app**

In the Rails app at `/Users/bolo/Documents/Code/ScionX/bots`, test the actual balance call:

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
bin/rails runner "
privy_wallet = Privy::Wallet.first
if privy_wallet
  result = PRIVY_CLIENT.wallets.balance(privy_wallet.privy_user_id, asset: 'usdc', chain: 'arbitrum', include_currency: 'usd')
  puts 'Response class: ' + result.data.class.name
  puts 'Has balances key: ' + result.data.key?('balances').to_s
  puts 'Balances: ' + result.data['balances'].inspect
  puts 'First balance: ' + result.data['balances'].first.inspect
end
"
```

Expected output should show:
```
Response class: Privy::Util::PrivyObject
Has balances key: true
Balances: [{"chain"=>"arbitrum", "asset"=>"usdc", ...}]
First balance: {"chain"=>"arbitrum", ...}
```

**Step 6: Commit**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add lib/privy/client.rb test/privy/wallet_service_test.rb
git commit -m "refactor: update Client to use convert_to_privy_object

- Update handle_response to wrap data in PrivyObject
- Add integration test for balance endpoint
- Verified PrivyObject works with wallet service"
```

---

## Task 5: Fix Balance Method in WalletService

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/services/wallet_service.rb:35-46`

**Step 1: Update balance method to work with PrivyObject**

The current code tries to access `response.data['balances']` which should work with PrivyObject. Verify the implementation:

```ruby
      def balance(wallet_id, params = {})
        response = request(:get, "wallets/#{wallet_id}/balance", params)

        return response unless response.success?

        # PrivyObject supports hash-like access with ['key']
        # Extract balances array and convert to Balance resource objects
        balances_data = response.data['balances'] || []
        balances = balances_data.map { |b| Privy::Resources::Balance.new(b) }

        # Return the array of Balance objects directly as data
        Privy::Client::Response.new(response.status_code, balances, nil)
      end
```

**Step 2: Test in Rails console**

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
bin/rails runner "
privy_wallet = Privy::Wallet.first
if privy_wallet
  usd_value = privy_wallet.balance
  puts 'Balance (USD): ' + usd_value.to_s
end
"
```

Expected: Should print the USD balance without errors

**Step 3: If no changes needed, document and skip commit**

If the code already works correctly with PrivyObject, document that no changes were needed.

---

## Task 6: Update Documentation

**Files:**
- Create: `/Users/bolo/Documents/Code/ScionX/partners/privy/docs/PRIVY_OBJECT.md`
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/README.md`

**Step 1: Create PrivyObject documentation**

Create: `/Users/bolo/Documents/Code/ScionX/partners/privy/docs/PRIVY_OBJECT.md`

```markdown
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
```

**Step 2: Update main README**

Add a section to `/Users/bolo/Documents/Code/ScionX/partners/privy/README.md`:

```markdown
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
```

**Step 3: Commit documentation**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add docs/PRIVY_OBJECT.md README.md
git commit -m "docs: add PrivyObject documentation

- Create comprehensive PrivyObject guide
- Add response objects section to README
- Document dual access, enumeration, and serialization
- Include usage examples and design philosophy"
```

---

## Task 7: Version Bump and Release

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/version.rb`
- Modify: `/Users/bolo/Documents/Code/ScionX/partners/privy/CHANGELOG.md`

**Step 1: Update version**

Modify `/Users/bolo/Documents/Code/ScionX/partners/privy/lib/privy/version.rb`:

```ruby
# frozen_string_literal: true

module Privy
  VERSION = '0.1.0' # Increment from current version
end
```

**Step 2: Update CHANGELOG**

Add to `/Users/bolo/Documents/Code/ScionX/partners/privy/CHANGELOG.md`:

```markdown
## [0.1.0] - 2025-11-26

### Changed
- **BREAKING**: Renamed `BridgedObject` to `PrivyObject` to avoid confusion with Bridge API integration
- API responses now wrapped in `PrivyObject` instead of `BridgedObject`

### Added
- Stripe-style helper methods: `keys()`, `values()`, `key?()`, `to_s()`
- Enumerable support for `PrivyObject` (each, map, select, etc.)
- Comprehensive documentation in `docs/PRIVY_OBJECT.md`
- Full test coverage for `PrivyObject` functionality

### Migration Guide
If you were accessing the internal `BridgedObject` class (unlikely), update to `PrivyObject`:

```ruby
# Before
obj = Privy::Util::BridgedObject.new(data)

# After
obj = Privy::Util::PrivyObject.new(data)
```

For normal API usage, no changes needed - responses work exactly the same.
```

**Step 3: Build and test gem**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
gem build privy.gemspec
```

Expected: Successfully builds `privy-0.1.0.gem`

**Step 4: Commit version bump**

```bash
cd /Users/bolo/Documents/Code/ScionX/partners/privy
git add lib/privy/version.rb CHANGELOG.md
git commit -m "chore: bump version to 0.1.0

- Update version for PrivyObject refactoring release
- Add comprehensive CHANGELOG entry with migration guide"
```

---

## Task 8: Update Rails App to Use New Gem Version

**Files:**
- Modify: `/Users/bolo/Documents/Code/ScionX/bots/Gemfile`

**Step 1: Update Gemfile to point to new version**

If using path dependency:

```ruby
gem 'privy', path: '../partners/privy'
```

If using git dependency, ensure it points to the branch with changes.

**Step 2: Bundle update**

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
bundle update privy
```

Expected: Successfully updates privy gem

**Step 3: Test balance call in Rails console**

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
bin/rails console
```

In console:
```ruby
privy_wallet = Privy::Wallet.first
usd_value = privy_wallet.balance
puts "Balance: $#{usd_value}"
```

Expected: Prints balance without NoMethodError

**Step 4: Run Rails tests**

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
bin/rails test
```

Expected: All tests pass

**Step 5: Commit Gemfile update**

```bash
cd /Users/bolo/Documents/Code/ScionX/bots
git add Gemfile Gemfile.lock
git commit -m "chore: update privy gem to 0.1.0

- Update to version with PrivyObject refactoring
- Fixes balance method NoMethodError"
```

---

## Verification Checklist

After completing all tasks, verify:

- [ ] All tests in Privy gem pass: `cd /Users/bolo/Documents/Code/ScionX/partners/privy && ruby test/privy/privy_object_test.rb`
- [ ] Gem builds successfully: `cd /Users/bolo/Documents/Code/ScionX/partners/privy && gem build privy.gemspec`
- [ ] Rails app balance call works: Test `privy_wallet.balance` in console
- [ ] Rails tests pass: `cd /Users/bolo/Documents/Code/ScionX/bots && bin/rails test`
- [ ] No references to `BridgedObject` remain: `grep -r "BridgedObject" /Users/bolo/Documents/Code/ScionX/partners/privy/lib`
- [ ] Documentation is complete and accurate

## Notes for Implementation

- **TDD Approach**: Write test first, see it fail, implement, see it pass, commit
- **Frequent Commits**: Commit after each passing test/feature
- **DRY Principle**: Don't repeat code - extract common patterns
- **YAGNI**: Only implement what's in the plan - no extra features
- **Test Coverage**: Every public method should have test coverage

## Related Skills

- @superpowers:executing-plans - Use this to execute the plan task-by-task
- @superpowers:test-driven-development - Follow TDD discipline throughout
- @superpowers:verification-before-completion - Verify each step before moving on
