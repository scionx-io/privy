# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'json/canonicalization'

module Privy
  # AuthorizationContext provides automatic request signing for Privy API calls.
  #
  # This implements Privy's authorization context pattern, allowing automatic
  # signature generation using authorization private keys.
  #
  # @example Using authorization private keys
  #   context = Privy::AuthorizationContext.new(
  #     authorization_private_keys: ['wallet-auth:YOUR_PRIVATE_KEY_BASE64']
  #   )
  #
  #   response = client.wallets.export(
  #     wallet_id,
  #     recipient_public_key: public_key,
  #     authorization_context: context
  #   )
  #
  # @example Adding to Privy global configuration
  #   Privy.configure do |config|
  #     config.app_id = 'your-app-id'
  #     config.app_secret = 'your-app-secret'
  #     config.authorization_private_key = 'wallet-auth:YOUR_KEY'
  #   end
  #
  #   # Now all requests that need signing will use this key automatically
  #   client = Privy::Client.new
  #   response = client.wallets.export(wallet_id, recipient_public_key: key)
  #
  class AuthorizationContext
    attr_reader :authorization_private_keys, :signatures

    # Initialize a new AuthorizationContext
    #
    # @param authorization_private_keys [Array<String>] List of authorization private keys
    # @param signatures [Array<String>] Pre-computed signatures to include
    def initialize(authorization_private_keys: [], signatures: [])
      @authorization_private_keys = Array(authorization_private_keys)
      @signatures = Array(signatures)
    end

    # Build a signature for the given request
    #
    # @param method [String] HTTP method (POST, GET, etc.)
    # @param url [String] Full URL of the request
    # @param body [Hash] Request body
    # @param app_id [String] Privy app ID
    # @return [String] Base64-encoded signature
    def sign_request(method:, url:, body:, app_id:)
      return signatures.first if signatures.any?
      return nil if authorization_private_keys.empty?

      # Build the payload to sign according to Privy's specification
      payload = {
        "body" => body,
        "headers" => { "privy-app-id" => app_id },
        "method" => method.to_s.upcase,
        "url" => url,
        "version" => 1
      }

      # Canonicalize (deterministic JSON serialization)
      serialized_payload = payload.to_json_c14n

      # Sign with the first authorization key (for now, single key support)
      private_key = authorization_private_keys.first
      generate_signature(private_key, serialized_payload)
    end

    # Check if this context has any signing capability
    #
    # @return [Boolean]
    def can_sign?
      authorization_private_keys.any? || signatures.any?
    end

    private

    # Generate an ECDSA P-256 signature
    #
    # @param auth_key [String] Authorization key in format "wallet-auth:BASE64_KEY"
    # @param message [String] Message to sign
    # @return [String] Base64-encoded signature
    def generate_signature(auth_key, message)
      # Remove the "wallet-auth:" prefix if present
      private_key_string = auth_key.sub(/^wallet-auth:/, '')

      # Construct PEM format for the private key
      private_key_pem = "-----BEGIN PRIVATE KEY-----\n#{private_key_string}\n-----END PRIVATE KEY-----"

      # Load the EC key and sign
      ec_key = OpenSSL::PKey::EC.new(private_key_pem)
      signature = ec_key.sign(OpenSSL::Digest::SHA256.new, message)

      Base64.strict_encode64(signature)
    rescue OpenSSL::PKey::ECError => e
      raise AuthorizationError, "Failed to sign request: Invalid authorization key - #{e.message}"
    rescue StandardError => e
      raise AuthorizationError, "Failed to sign request: #{e.message}"
    end

    class << self
      # Create a new AuthorizationContext builder
      #
      # @return [Builder]
      def builder
        Builder.new
      end
    end

    # Builder pattern for constructing AuthorizationContext
    class Builder
      def initialize
        @authorization_private_keys = []
        @signatures = []
      end

      # Add an authorization private key
      #
      # @param key [String] Authorization private key
      # @return [Builder] self for chaining
      def add_authorization_private_key(key)
        @authorization_private_keys << key
        self
      end

      # Add a pre-computed signature
      #
      # @param signature [String] Base64-encoded signature
      # @return [Builder] self for chaining
      def add_signature(signature)
        @signatures << signature
        self
      end

      # Build the AuthorizationContext
      #
      # @return [AuthorizationContext]
      def build
        AuthorizationContext.new(
          authorization_private_keys: @authorization_private_keys,
          signatures: @signatures
        )
      end
    end
  end

end
