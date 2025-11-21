# Automatic Request Signing and Encryption with Privy Ruby SDK

This document explains how to use Privy's **AuthorizationContext** for automatic request signing and **HPKE automation** for wallet exports in the Ruby SDK.

## Overview

The Privy Ruby SDK provides two levels of automation:

### 1. Authorization Signatures (All Signed Requests)

The **Authorization Context** enables automatic request signing for any Privy API method that requires signatures. The SDK will automatically:

1. Construct the proper request payload
2. Canonicalize the JSON (deterministic serialization using RFC 8785)
3. Generate ECDSA P-256 signatures
4. Include signatures in the API request headers

### 2. HPKE Encryption (Wallet Exports)

For wallet export operations, the SDK provides **full automation** including encryption:

1. Generate ephemeral HPKE key pairs (P-256) in memory
2. Sign the request with your authorization key
3. Send the export request with the public key
4. Decrypt the HPKE-encrypted response
5. Return the plain wallet private key

**No manual cryptography, no key files, no external tools required!**

## Quick Start

### Fully Automated Wallet Export (Recommended)

The simplest way to export a wallet - everything is automatic:

```ruby
require 'privy'

# Configure once
Privy.configure do |config|
  config.app_id = 'your-app-id'
  config.app_secret = 'your-app-secret'
  config.authorization_private_key = 'wallet-auth:YOUR_BASE64_KEY'
end

# Create client
client = Privy::Client.new

# Export wallet - EVERYTHING is automatic!
# Returns the decrypted wallet private key directly
private_key = client.wallets.export(wallet_id)
# => "0xabc123..."

# Use the private key
require 'eth'
key = Eth::Key.new(priv: private_key)
puts key.address  # => "0x..."
```

That's it! The SDK handles:
- ✓ HPKE key generation (ephemeral, in-memory)
- ✓ Authorization signature generation
- ✓ API request construction
- ✓ HPKE decryption of response
- ✓ Returns plain private key

**No files created, no manual cryptography, no external dependencies.**

## Authorization Context Options

The `AuthorizationContext` supports several signing methods:

### 1. Authorization Private Keys

Sign requests using authorization keys created in the Privy Dashboard or API.

```ruby
# Using global configuration
Privy.configure do |config|
  config.authorization_private_key = 'wallet-auth:YOUR_KEY'
end

# Or per-request
auth_context = Privy::AuthorizationContext.new(
  authorization_private_keys: ['wallet-auth:YOUR_KEY']
)

response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_context: auth_context
)
```

### 2. Builder Pattern

For a more Java/TypeScript-like API:

```ruby
auth_context = Privy::AuthorizationContext.builder
  .add_authorization_private_key('wallet-auth:KEY_1')
  .add_authorization_private_key('wallet-auth:KEY_2')  # For key quorums
  .build

response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_context: auth_context
)
```

### 3. Pre-computed Signatures

If you compute signatures externally (e.g., in a KMS):

```ruby
# Your external signing logic
signature = compute_signature_in_kms(request_payload)

auth_context = Privy::AuthorizationContext.new(
  signatures: [signature]
)

response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_context: auth_context
)
```

### 4. Key Quorums (Multiple Signatures)

For wallets requiring multiple signatures:

```ruby
auth_context = Privy::AuthorizationContext.new(
  authorization_private_keys: [
    'wallet-auth:KEY_1',
    'wallet-auth:KEY_2',
    'wallet-auth:KEY_3'
  ]
)

# The SDK will generate all required signatures
response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_context: auth_context
)
```

## Supported Operations

### Wallet Export (Fully Automated)

The default `export` method handles everything automatically:

```ruby
# Fully automated - returns decrypted private key
private_key = client.wallets.export(wallet_id)
# => "0xabc123..."
```

### Wallet Export (Raw Response)

If you need the encrypted response without automatic decryption:

```ruby
# Generate your own HPKE keys
keys = Privy::HpkeHelper.generate_keys

# Get encrypted response
response = client.wallets.export_raw(
  wallet_id,
  recipient_public_key: keys[:public_key]
)

if response.success?
  # Manually decrypt
  private_key = Privy::HpkeHelper.decrypt(
    ciphertext: response.data.ciphertext,
    encapsulated_key: response.data.encapsulated_key,
    private_key: keys[:private_key]
  )
end
```

### Wallet Update

```ruby
response = client.wallets.update(
  wallet_id,
  authorization_context: auth_context,  # Optional if global config is set
  # ... other update parameters
)
```

## HPKE Helper Utilities

The SDK provides `Privy::HpkeHelper` for manual HPKE operations:

### Generate HPKE Keys

```ruby
keys = Privy::HpkeHelper.generate_keys
# => {
#   public_key: "base64-encoded-spki-public-key",
#   private_key: OpenSSL::PKey::EC instance
# }
```

### Decrypt HPKE Response

```ruby
plaintext = Privy::HpkeHelper.decrypt(
  ciphertext: "base64-encoded-ciphertext",
  encapsulated_key: "base64-encoded-encapsulated-key",
  private_key: ec_private_key,
  info: '',  # Optional application context
  aad: ''    # Optional additional authenticated data
)
```

The helper uses the standard HPKE algorithm suite:
- **KEM**: DHKEM(P-256, HKDF-SHA256)
- **KDF**: HKDF-SHA256
- **AEAD**: ChaCha20-Poly1305

## Configuration Precedence

The SDK uses the following priority for authorization:

1. **Explicit `authorization_context` parameter** - Highest priority
2. **Client-level `authorization_private_key`** - Set in `Client.new`
3. **Global `Privy.authorization_private_key`** - Set in `Privy.configure`

Example:

```ruby
# Global configuration (lowest priority)
Privy.configure do |config|
  config.authorization_private_key = 'wallet-auth:GLOBAL_KEY'
end

# Client-level (medium priority)
client = Privy::Client.new(
  authorization_private_key: 'wallet-auth:CLIENT_KEY'
)

# Per-request (highest priority)
auth_context = Privy::AuthorizationContext.new(
  authorization_private_keys: ['wallet-auth:REQUEST_KEY']
)

# This will use REQUEST_KEY
response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_context: auth_context
)
```

## Migration from Manual Implementation

### Before (100+ Lines of Manual Code)

```ruby
require 'json/canonicalization'
require 'openssl'
require 'base64'
require 'hpke'
require 'net/http'

# 1. Generate HPKE keys
recipient_key = OpenSSL::PKey::EC.generate('prime256v1')
public_key_spki = recipient_key.public_to_der
recipient_public_key = Base64.strict_encode64(public_key_spki)

# 2. Construct signature payload
url = "https://api.privy.io/api/v1/wallets/#{wallet_id}/export"
body = {
  "encryption_type" => "HPKE",
  "recipient_public_key" => recipient_public_key
}

payload = {
  "body" => body,
  "headers" => { "privy-app-id" => app_id },
  "method" => "POST",
  "url" => url,
  "version" => 1
}

# 3. Canonicalize and sign
serialized = payload.to_json_c14n
key_string = auth_key.sub("wallet-auth:", "")
private_key_pem = "-----BEGIN PRIVATE KEY-----\n#{key_string}\n-----END PRIVATE KEY-----"
ec_key = OpenSSL::PKey::EC.new(private_key_pem)
signature = ec_key.sign(OpenSSL::Digest::SHA256.new, serialized)
auth_signature = Base64.strict_encode64(signature)

# 4. Make HTTP request
uri = URI(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(uri)
request['Authorization'] = "Basic #{Base64.strict_encode64("#{app_id}:#{app_secret}")}"
request['privy-app-id'] = app_id
request['privy-authorization-signature'] = auth_signature
request['Content-Type'] = 'application/json'
request.body = JSON.generate(body)

response = http.request(request)
result = JSON.parse(response.body)

# 5. Decrypt HPKE response
ciphertext = Base64.decode64(result['ciphertext'])
encapsulated_key = Base64.decode64(result['encapsulated_key'])
hpke = HPKE.new(0x0010, 0x0001, 0x0003)
context = hpke.setup_base_r(encapsulated_key, recipient_key, '')
decrypted_key = context.open('', ciphertext)

puts "Private Key: #{decrypted_key}"
```

### After (3 Lines of Code)

```ruby
# Configure once
Privy.configure do |config|
  config.app_id = 'your-app-id'
  config.app_secret = 'your-app-secret'
  config.authorization_private_key = 'wallet-auth:YOUR_KEY'
end

# Export wallet - everything automatic!
client = Privy::Client.new
private_key = client.wallets.export(wallet_id)
puts "Private Key: #{private_key}"
```

**That's a 97% reduction in code!** 🎉

## Error Handling

The SDK provides specific error types for different failure scenarios:

```ruby
begin
  private_key = client.wallets.export(wallet_id)
  puts "Success: #{private_key}"

rescue Privy::HpkeError => e
  # HPKE encryption/decryption failures
  puts "Decryption failed: #{e.message}"
  # Common causes:
  # - Invalid ciphertext format
  # - Network corruption
  # - Algorithm mismatch

rescue Privy::AuthorizationError => e
  # Authorization signature failures
  puts "Authorization failed: #{e.message}"
  # Common causes:
  # - Invalid authorization private key
  # - Key doesn't have permission for this wallet
  # - Incorrect key format

rescue Privy::NotFoundError => e
  # Wallet doesn't exist
  puts "Wallet not found: #{e.message}"

rescue Privy::ForbiddenError => e
  # Permission denied
  puts "Permission denied: #{e.message}"

rescue Privy::ApiError => e
  # Generic API errors
  puts "API error: #{e.message}"

rescue StandardError => e
  # Unexpected errors
  puts "Unexpected error: #{e.message}"
end
```

## Examples

See the `exemples/` directory for complete working examples:

- **`fully_automated_export.rb`** - The simplest possible wallet export (recommended)
- **`export_with_autosigning.rb`** - Autosigning with manual HPKE handling
- **`authorization_context_advanced.rb`** - Advanced AuthorizationContext patterns

## Technical Details

### Authorization Signature Algorithm

The SDK uses **ECDSA P-256 (secp256r1)** with **SHA-256** hashing for all authorization signatures.

**Signature Payload Format:**

```json
{
  "body": { /* request body */ },
  "headers": { "privy-app-id": "your-app-id" },
  "method": "POST",
  "url": "https://api.privy.io/api/v1/wallets/xxx/export",
  "version": 1
}
```

The JSON is canonicalized using RFC 8785 (JSON Canonicalization Scheme) via the `json-canonicalization` gem.

**Authorization Key Format:**

Authorization private keys can be in either format:
1. **With prefix**: `wallet-auth:BASE64_ENCODED_PRIVATE_KEY`
2. **Without prefix**: `BASE64_ENCODED_PRIVATE_KEY`

The SDK handles both formats automatically.

### HPKE Encryption Algorithm

For wallet exports, the SDK uses the standard **HPKE (Hybrid Public Key Encryption)** algorithm suite:

- **KEM**: DHKEM(P-256, HKDF-SHA256) - Algorithm ID: `0x0010`
- **KDF**: HKDF-SHA256 - Algorithm ID: `0x0001`
- **AEAD**: ChaCha20-Poly1305 - Algorithm ID: `0x0003`

**Key Management:**
- Ephemeral P-256 key pairs are generated in memory using OpenSSL
- Public keys are exported in SPKI (SubjectPublicKeyInfo) DER format
- Private keys are kept in memory only and never written to disk
- Keys are discarded after decryption

**Security Properties:**
- Forward secrecy (ephemeral keys per export)
- Authenticated encryption (ChaCha20-Poly1305 AEAD)
- IND-CCA2 security under HPKE standard

## FAQ

### Q: Do I need to configure authorization keys for all requests?

**A:** No, only requests that modify sensitive resources (like exporting wallets or updating policies) require authorization signatures. Read operations like listing wallets don't require signing.

### Q: Can I use different authorization keys for different wallets?

**A:** Yes! Use per-request `authorization_context` parameters:

```ruby
auth_context_wallet_1 = Privy::AuthorizationContext.new(
  authorization_private_keys: ['wallet-auth:KEY_FOR_WALLET_1']
)

auth_context_wallet_2 = Privy::AuthorizationContext.new(
  authorization_private_keys: ['wallet-auth:KEY_FOR_WALLET_2']
)

client.wallets.export(wallet_1_id, authorization_context: auth_context_wallet_1)
client.wallets.export(wallet_2_id, authorization_context: auth_context_wallet_2)
```

### Q: What if I need to sign requests in a separate service (KMS)?

**A:** Compute the signature externally and pass it via the `signatures` parameter:

```ruby
# In your KMS service
signature = your_kms.sign(payload)

# In your application
auth_context = Privy::AuthorizationContext.new(signatures: [signature])
```

### Q: Can I still use the old `authorization_signature` parameter?

**A:** Yes! The old parameter is still supported for backward compatibility:

```ruby
response = client.wallets.export(
  wallet_id,
  recipient_public_key: public_key,
  authorization_signature: manually_computed_signature
)
```

However, we recommend migrating to `AuthorizationContext` for better ergonomics and future features.

## Future Enhancements

Planned features for future releases:

- **User JWT support** - Sign requests using user authentication tokens
- **Custom signing functions** - Pass Ruby blocks/procs for custom signing logic
- **Automatic key rotation** - Support for rotating authorization keys
- **Signature caching** - Cache signatures for identical requests

## Support

For issues or questions:

- GitHub Issues: [privy-ruby-sdk/issues](https://github.com/your-org/privy-ruby-sdk/issues)
- Documentation: [docs.privy.io](https://docs.privy.io)
- Email: support@privy.io
