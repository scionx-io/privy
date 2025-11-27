## [0.0.2] - 2025-11-26

### Changed
- **BREAKING**: Renamed `BridgedObject` to `PrivyObject` to avoid confusion with Bridge API integration
- All API responses now use `PrivyObject` wrapper instead of `BridgedObject`

### Added
- Stripe-style helper methods to PrivyObject:
  - `keys()` - get all attribute names
  - `values()` - get all attribute values
  - `to_s()` - pretty JSON string representation
  - `key?(key)` - check if attribute exists
  - `to_hash` alias for `to_h`
- Enumerable support - PrivyObject now includes Enumerable module
  - Enables `each`, `map`, `select`, `filter`, `count`, and all other Enumerable methods
  - Iterate over key-value pairs: `obj.each { |k, v| ... }`
- Comprehensive test suite with 25+ tests covering all functionality
- Complete documentation in `docs/PRIVY_OBJECT.md`
- Response objects section in README

### Fixed
- Balance method now correctly accesses PrivyObject with `['balances']` syntax
- Method access (`obj.key`) and hash access (`obj['key']`) both work seamlessly

### Migration Guide

**If you were directly using BridgedObject** (unlikely):

```ruby
# Before
obj = Privy::Util::BridgedObject.new(data)

# After
obj = Privy::Util::PrivyObject.new(data)
```

**For normal API usage**, no code changes needed. All responses automatically use PrivyObject and are backward compatible:

```ruby
# This code works the same before and after
response = client.wallets.retrieve(wallet_id)
address = response.data['address']  # Still works
address = response.data.address     # Also works
```