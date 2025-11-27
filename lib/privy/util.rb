# frozen_string_literal: true

require 'openssl'
require 'base64'

module Privy
  module Util
    class << self
      # Sign a request payload using the private key
      def sign_request(private_key_pem, method, endpoint, payload = {})
        # Construct the message to sign according to Privy's specification
        # Implementation would follow Privy's signing guidelines
        begin
          private_key = OpenSSL::PKey::EC.new(private_key_pem)
          
          # Create the message to sign (method + endpoint + payload)
          payload_json = payload.is_a?(String) ? payload : payload.to_json
          message = "#{method.upcase}#{endpoint}#{payload_json}"
          
          # Sign the message
          digest = OpenSSL::Digest::SHA256.new
          signature = private_key.sign(digest, message)
          
          # Return base64 encoded signature
          Base64.encode64(signature).strip
        rescue => e
          raise "Failed to sign request: #{e.message}"
        end
      end

      # Verify a signature
      def verify_signature(public_key_pem, signature_b64, method, endpoint, payload = {})
        begin
          public_key = OpenSSL::PKey::EC.new(public_key_pem)
          signature = Base64.decode64(signature_b64)
          
          payload_json = payload.is_a?(String) ? payload : payload.to_json
          message = "#{method.upcase}#{endpoint}#{payload_json}"
          
          digest = OpenSSL::Digest::SHA256.new
          public_key.verify(digest, signature, message)
        rescue => e
          raise "Failed to verify signature: #{e.message}"
        end
      end

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
    end

    # A simple class to allow hash-like and method-based access to API response objects
    class PrivyObject
      include Enumerable
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

      # Enumerable support - iterate over key-value pairs
      def each(&block)
        @attributes.each(&block)
      end
    end
  end
end