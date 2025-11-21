# 🚀 NEW: Full Automation for Wallet Exports

## The Problem (Before)

Exporting wallets from Privy required ~100 lines of complex cryptographic code:

```ruby
# ❌ Manual HPKE key generation
# ❌ Manual JSON canonicalization
# ❌ Manual P-256 ECDSA signing
# ❌ Manual HTTP request construction
# ❌ Manual HPKE decryption
# ❌ Error-prone and hard to maintain
```

## The Solution (Now)

**3 lines of code. Everything automated. Zero cryptography knowledge required.**

```ruby
Privy.configure { |c| c.authorization_private_key = 'wallet-auth:YOUR_KEY' }
client = Privy::Client.new
private_key = client.wallets.export(wallet_id)  # ✨ Magic happens here
```

## What Gets Automated

| Operation | Before | After |
|-----------|--------|-------|
| HPKE key generation | Manual (10+ lines) | Automatic |
| Authorization signing | Manual (20+ lines) | Automatic |
| JSON canonicalization | Manual (require gem) | Automatic |
| HTTP request | Manual (15+ lines) | Automatic |
| HPKE decryption | Manual (10+ lines) | Automatic |
| Error handling | DIY | Built-in |

## Features

### ✨ Full Automation
- **HPKE encryption/decryption** - Ephemeral P-256 keys generated in memory
- **Authorization signatures** - Automatic ECDSA P-256 signing
- **JSON canonicalization** - RFC 8785 compliance built-in
- **No file I/O** - All keys kept in memory, never written to disk

### 🛡️ Security First
- **Ephemeral keys** - New key pair for each export (forward secrecy)
- **Memory-only** - Private keys never touch disk
- **Standard algorithms** - P-256, HKDF-SHA256, ChaCha20-Poly1305
- **Auditable** - All crypto code in one module

### 🎯 Developer Experience
- **3 lines of code** - Down from 100+
- **Zero crypto knowledge** - No OpenSSL, no Base64, no HPKE
- **Professional errors** - Specific exception types
- **Great documentation** - Examples, guides, API docs

## Quick Start

### 1. Configure (Once)

```ruby
require 'privy'

Privy.configure do |config|
  config.app_id = ENV['PRIVY_APP_ID']
  config.app_secret = ENV['PRIVY_APP_SECRET']
  config.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY']
end
```

### 2. Export (Simple)

```ruby
client = Privy::Client.new
private_key = client.wallets.export('wallet-id')
# => "0xabc123..."

# Verify it works
require 'eth'
key = Eth::Key.new(priv: private_key)
puts key.address  # => "0x..."
```

### 3. Handle Errors (Built-in)

```ruby
begin
  private_key = client.wallets.export(wallet_id)
rescue Privy::HpkeError => e
  puts "Decryption failed: #{e.message}"
rescue Privy::AuthorizationError => e
  puts "Authorization failed: #{e.message}"
rescue Privy::ApiError => e
  puts "API error: #{e.message}"
end
```

## Advanced Usage

### Per-Request Authorization

```ruby
# Different authorization keys for different wallets
auth_ctx = Privy::AuthorizationContext.new(
  authorization_private_keys: ['wallet-auth:SPECIFIC_KEY']
)

private_key = client.wallets.export(
  wallet_id,
  authorization_context: auth_ctx
)
```

### Key Quorums (Multiple Signatures)

```ruby
# Wallets requiring multiple signatures
auth_ctx = Privy::AuthorizationContext.new(
  authorization_private_keys: [
    'wallet-auth:KEY1',
    'wallet-auth:KEY2',
    'wallet-auth:KEY3'
  ]
)

private_key = client.wallets.export(wallet_id, authorization_context: auth_ctx)
```

### Manual HPKE Control

```ruby
# When you need fine-grained control
keys = Privy::HpkeHelper.generate_keys

response = client.wallets.export_raw(
  wallet_id,
  recipient_public_key: keys[:public_key]
)

decrypted = Privy::HpkeHelper.decrypt(
  ciphertext: response.data.ciphertext,
  encapsulated_key: response.data.encapsulated_key,
  private_key: keys[:private_key]
)
```

## Code Comparison

### Before (Manual - 100+ lines)

<details>
<summary>Click to expand the old way...</summary>

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

# 2. Build signature payload
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

</details>

### After (Automated - 3 lines)

```ruby
Privy.configure { |c| c.authorization_private_key = 'wallet-auth:KEY' }
client = Privy::Client.new
private_key = client.wallets.export(wallet_id)
```

**97% reduction in code!** 🎉

## Documentation

- **[AUTOSIGNING.md](./AUTOSIGNING.md)** - Complete guide
- **[exemples/fully_automated_export.rb](./exemples/fully_automated_export.rb)** - Simplest example
- **[exemples/authorization_context_advanced.rb](./exemples/authorization_context_advanced.rb)** - Advanced patterns

## Migration Guide

### Step 1: Update gem dependencies

The gem already includes all necessary dependencies:
- `json-canonicalization` (for RFC 8785)
- `hpke` (for HPKE encryption)
- `openssl` (built-in Ruby)

### Step 2: Replace manual code

Find your manual export code and replace it:

```diff
- # 100+ lines of manual HPKE and signing code...
+ Privy.configure { |c| c.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY'] }
+ client = Privy::Client.new
+ private_key = client.wallets.export(wallet_id)
```

### Step 3: Update error handling

```diff
- rescue => e
-   puts "Error: #{e.message}"
+ rescue Privy::HpkeError => e
+   puts "Decryption failed: #{e.message}"
+ rescue Privy::AuthorizationError => e
+   puts "Authorization failed: #{e.message}"
+ rescue Privy::ApiError => e
+   puts "API error: #{e.message}"
```

## Technical Details

### Authorization Signatures
- **Algorithm**: ECDSA P-256 with SHA-256
- **Format**: RFC 8785 canonical JSON
- **Header**: `privy-authorization-signature`

### HPKE Encryption
- **KEM**: DHKEM(P-256, HKDF-SHA256)
- **KDF**: HKDF-SHA256
- **AEAD**: ChaCha20-Poly1305
- **Key lifecycle**: Generate → Use → Discard

## FAQ

**Q: Is this secure?**
A: Yes! Uses standard algorithms (P-256, HPKE), ephemeral keys, and memory-only key storage.

**Q: Do I need to manage HPKE keys?**
A: No! The gem generates ephemeral keys in memory for each export.

**Q: What about backward compatibility?**
A: Old APIs still work. You can still pass `authorization_signature` manually if needed.

**Q: Can I use different keys for different wallets?**
A: Yes! Use per-request `authorization_context` parameter.

**Q: Where are the keys stored?**
A: In memory only. Never written to disk. Discarded after use.

**Q: What if I need manual control?**
A: Use `export_raw()` and `HpkeHelper` utilities for full control.

## Support

- **GitHub Issues**: Report bugs or request features
- **Documentation**: See AUTOSIGNING.md for complete guide
- **Examples**: Check `exemples/` directory for working code

---

## Summary

✅ **3 lines of code** instead of 100+
✅ **Zero cryptography knowledge** required
✅ **Fully automated** HPKE and signing
✅ **Production ready** with proper error handling
✅ **Secure by default** with ephemeral keys
✅ **Backward compatible** with old APIs

Start using it today:

```ruby
Privy.configure { |c| c.authorization_private_key = ENV['PRIVY_AUTHORIZATION_KEY'] }
client = Privy::Client.new
private_key = client.wallets.export(wallet_id)
```

That's it! 🚀
