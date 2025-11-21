module Privy
  module Services
    class WalletService < BaseService
      def create(**params)
        idempotency_key = params.delete(:idempotency_key)
        response = request(:post, 'wallets', params, idempotency_key: idempotency_key)

        return response unless response.success?

        # Convert response data to Wallet resource object
        Privy::Resources::Wallet.new(response.data.to_h)
      end

      def retrieve(wallet_id, params = {})
        response = request(:get, "wallets/#{wallet_id}", params)

        return response unless response.success?

        Privy::Resources::Wallet.new(response.data.to_h)
      end

      def list(params = {})
        response = request(:get, 'wallets', params)

        return response unless response.success?

        # If the response contains an array of wallets, convert each to a Wallet object
        if response.data.is_a?(Array)
          response.data.map { |wallet_data| Privy::Resources::Wallet.new(wallet_data.to_h) }
        else
          response
        end
      end

      def balance(wallet_id, params = {})
        request(:get, "wallets/#{wallet_id}/balance", params)
      end

      def transactions(wallet_id, params = {})
        request(:get, "wallets/#{wallet_id}/transactions", params)
      end

      # Export a wallet and automatically decrypt the private key
      #
      # This method provides full automation:
      # 1. Generates ephemeral HPKE keys in memory
      # 2. Auto-signs the request with AuthorizationContext
      # 3. Decrypts the response
      # 4. Returns the plain wallet private key
      #
      # No manual key management or cryptography required!
      #
      # @param wallet_id [String] The wallet ID to export
      # @param authorization_signature [String] Optional pre-computed signature
      # @param authorization_context [AuthorizationContext] Optional authorization context
      #
      # @return [String] The decrypted wallet private key (e.g., "0xabc123...")
      #
      # @raise [HpkeError] If decryption fails
      # @raise [ApiError] If the API request fails
      #
      # @example Simple usage with global config
      #   Privy.configure do |config|
      #     config.authorization_private_key = 'wallet-auth:YOUR_KEY'
      #   end
      #
      #   client = Privy::Client.new
      #   private_key = client.wallets.export(wallet_id)
      #   # => "0xabc123..."
      #
      # @example With explicit authorization context
      #   auth_ctx = Privy::AuthorizationContext.new(
      #     authorization_private_keys: ['wallet-auth:KEY']
      #   )
      #   private_key = client.wallets.export(wallet_id, authorization_context: auth_ctx)
      #
      def export(wallet_id, authorization_signature: nil, authorization_context: nil)
        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        # Generate ephemeral HPKE keys for this export
        hpke_keys = HpkeHelper.generate_keys

        # Make the export request with auto-generated public key
        response = export_raw(
          wallet_id,
          recipient_public_key: hpke_keys[:public_key],
          authorization_signature: authorization_signature,
          authorization_context: authorization_context
        )

        # Return early if request failed
        return response unless response.success?

        # Decrypt the response and return the plain private key
        HpkeHelper.decrypt_export_response(response, hpke_keys[:private_key])
      end

      # Export a wallet and return the raw encrypted response
      #
      # This is the low-level method that returns the encrypted response
      # without automatic decryption. Use this if you want to handle
      # HPKE decryption yourself or store the encrypted data.
      #
      # @param wallet_id [String] The wallet ID to export
      # @param encryption_type [String] Encryption type (default: 'HPKE')
      # @param recipient_public_key [String] Base64-encoded SPKI public key
      # @param authorization_signature [String] Optional pre-computed signature
      # @param authorization_context [AuthorizationContext] Optional authorization context
      #
      # @return [Privy::Client::Response] The encrypted response
      #
      # @example
      #   keys = Privy::HpkeHelper.generate_keys
      #   response = client.wallets.export_raw(
      #     wallet_id,
      #     recipient_public_key: keys[:public_key]
      #   )
      #
      #   if response.success?
      #     # Decrypt manually
      #     private_key = Privy::HpkeHelper.decrypt(
      #       ciphertext: response.data.ciphertext,
      #       encapsulated_key: response.data.encapsulated_key,
      #       private_key: keys[:private_key]
      #     )
      #   end
      #
      def export_raw(wallet_id, encryption_type: 'HPKE', recipient_public_key:, authorization_signature: nil, authorization_context: nil)
        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        params = {
          encryption_type: encryption_type,
          recipient_public_key: recipient_public_key
        }
        request(:post, "wallets/#{wallet_id}/export", params, authorization_signature: authorization_signature, authorization_context: authorization_context)
      end

      def update(wallet_id, authorization_signature: nil, authorization_context: nil, **params)
        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        request(:patch, "wallets/#{wallet_id}", params, authorization_signature: authorization_signature, authorization_context: authorization_context)
      end

      def create_owner(public_keys:)
        params = { public_keys: public_keys }
        request(:post, 'key_quorums', params)
      end
    end
  end
end