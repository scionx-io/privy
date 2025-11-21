# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'hpke'

module Privy
  # HpkeHelper provides utilities for HPKE (Hybrid Public Key Encryption) operations
  # used in Privy's wallet export API.
  #
  # This module handles:
  # - Generating ephemeral HPKE key pairs (P-256)
  # - Decrypting HPKE-encrypted responses from Privy API
  # - Managing keys in memory (no file I/O required)
  #
  # @example Basic usage
  #   keys = Privy::HpkeHelper.generate_keys
  #   # => { public_key: "base64...", private_key: OpenSSL::PKey::EC }
  #
  #   decrypted = Privy::HpkeHelper.decrypt(
  #     ciphertext: response.data.ciphertext,
  #     encapsulated_key: response.data.encapsulated_key,
  #     private_key: keys[:private_key]
  #   )
  #
  module HpkeHelper
    # HPKE Algorithm IDs for Privy API
    # See: https://www.rfc-editor.org/rfc/rfc9180.html#name-key-encapsulation-mechanism
    KEM_P256_HKDF_SHA256 = 0x0010  # DHKEM(P-256, HKDF-SHA256)
    KDF_HKDF_SHA256 = 0x0001       # HKDF-SHA256
    AEAD_CHACHA20_POLY1305 = 0x0003 # ChaCha20Poly1305

    class << self
      # Generate a new ephemeral HPKE key pair for wallet export
      #
      # The generated keys are kept in memory and never written to disk.
      # The public key is returned in SPKI format (base64-encoded DER),
      # which is the format expected by Privy's API.
      #
      # @return [Hash] A hash containing:
      #   - :public_key [String] Base64-encoded SPKI public key for the API
      #   - :private_key [OpenSSL::PKey::EC] Private key for decryption
      #
      # @example
      #   keys = Privy::HpkeHelper.generate_keys
      #   puts keys[:public_key]  # Send this to Privy API
      #   # Use keys[:private_key] for decryption later
      #
      def generate_keys
        # Generate P-256 (secp256r1) key pair
        ec_key = OpenSSL::PKey::EC.generate('prime256v1')

        # Export public key in SPKI format (SubjectPublicKeyInfo)
        # This is the standard format for HPKE recipient public keys
        public_key_spki = ec_key.public_to_der
        public_key_b64 = Base64.strict_encode64(public_key_spki)

        {
          public_key: public_key_b64,
          private_key: ec_key
        }
      rescue OpenSSL::PKey::ECError => e
        raise HpkeError, "Failed to generate HPKE keys: #{e.message}"
      end

      # Decrypt an HPKE-encrypted response from Privy API
      #
      # This method implements the HPKE decryption flow using:
      # - KEM: DHKEM(P-256, HKDF-SHA256)
      # - KDF: HKDF-SHA256
      # - AEAD: ChaCha20Poly1305
      #
      # @param ciphertext [String] Base64-encoded encrypted data
      # @param encapsulated_key [String] Base64-encoded encapsulated public key from sender
      # @param private_key [OpenSSL::PKey::EC] Recipient's private key (from generate_keys)
      # @param info [String] Optional application-specific context (default: empty string)
      # @param aad [String] Optional additional authenticated data (default: empty string)
      #
      # @return [String] Decrypted plaintext (wallet private key)
      #
      # @raise [HpkeError] If decryption fails
      #
      # @example
      #   # After getting encrypted response from Privy API
      #   decrypted_key = Privy::HpkeHelper.decrypt(
      #     ciphertext: response.data.ciphertext,
      #     encapsulated_key: response.data.encapsulated_key,
      #     private_key: recipient_private_key
      #   )
      #
      def decrypt(ciphertext:, encapsulated_key:, private_key:, info: '', aad: '')
        # Decode base64-encoded inputs
        ciphertext_bytes = Base64.decode64(ciphertext)
        encapsulated_key_bytes = Base64.decode64(encapsulated_key)

        # Initialize HPKE with Privy's algorithm suite
        # KEM: P-256 + HKDF-SHA256
        # KDF: HKDF-SHA256
        # AEAD: ChaCha20-Poly1305
        hpke = HPKE.new(KEM_P256_HKDF_SHA256, KDF_HKDF_SHA256, AEAD_CHACHA20_POLY1305)

        # Setup receiver context
        # This derives the shared secret and initializes the AEAD cipher
        context = hpke.setup_base_r(encapsulated_key_bytes, private_key, info)

        # Decrypt the ciphertext
        # The AAD (additional authenticated data) is typically empty for wallet exports
        plaintext = context.open(aad, ciphertext_bytes)

        plaintext
      rescue HPKE::Error => e
        raise HpkeError, "HPKE decryption failed: #{e.message}"
      rescue StandardError => e
        raise HpkeError, "Failed to decrypt response: #{e.message}"
      end

      # Convenience method for the full export workflow
      #
      # This is an internal helper that:
      # 1. Generates ephemeral HPKE keys
      # 2. Returns the public key for API request
      # 3. Keeps the private key for later decryption
      #
      # @return [Hash] Keys for export workflow
      #
      # @api private
      #
      def prepare_export
        generate_keys
      end

      # Decrypt an export response in one call
      #
      # @param response [Privy::Client::Response] API response from wallet export
      # @param private_key [OpenSSL::PKey::EC] Recipient's private key
      #
      # @return [String] Decrypted wallet private key
      #
      # @raise [HpkeError] If response is invalid or decryption fails
      #
      # @api private
      #
      def decrypt_export_response(response, private_key)
        unless response.success?
          raise HpkeError, "Cannot decrypt failed response: #{response.error&.message}"
        end

        unless response.data&.ciphertext && response.data&.encapsulated_key
          raise HpkeError, "Invalid export response: missing ciphertext or encapsulated_key"
        end

        decrypt(
          ciphertext: response.data.ciphertext,
          encapsulated_key: response.data.encapsulated_key,
          private_key: private_key
        )
      end
    end
  end
end
