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