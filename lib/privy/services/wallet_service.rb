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
        response = request(:get, "wallets/#{wallet_id}/balance", params)

        return response unless response.success?

        # Convert balances array to Balance resource objects
        balances_data = response.data['balances'] || []
        balances = balances_data.map { |b| Privy::Resources::Balance.new(b) }

        # Return the array of Balance objects directly as data
        Privy::Client::Response.new(response.status_code, balances, nil)
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

      # Send a transaction using the eth_sendTransaction RPC method
      #
      # @param wallet_id [String] The wallet ID to send the transaction from
      # @param transaction_params [Hash] The transaction parameters including 'to', 'value', etc.
      # @param caip2 [String] The CAIP-2 chain identifier (e.g., 'eip155:11155111')
      # @param sponsor [Boolean] Whether to enable gas sponsorship for this transaction
      # @param chain_type [String] The chain type (default: 'ethereum')
      # @param address [String] Optional address parameter
      # @param authorization_signature [String] Optional pre-computed signature
      # @param authorization_context [AuthorizationContext] Optional authorization context
      # @param return_resource [Boolean] Whether to return a Transaction resource object instead of raw response
      #
      # @return [Privy::Client::Response, Privy::Resources::Transaction] Response containing transaction hash and other details, or Transaction resource if return_resource: true
      #
      # @example Send a simple transaction
      #   transaction_params = {
      #     transaction: {
      #       to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
      #       value: '0x2386F26FC10000'
      #     }
      #   }
      #   response = client.wallets.eth_send_transaction(
      #     'wallet_id_123',
      #     transaction_params,
      #     caip2: 'eip155:11155111',
      #     sponsor: true
      #   )
      #   if response.success?
      #     puts "Transaction hash: #{response.data['data']['hash']}"
      #   end
      #
      # @example Send a transaction and get Transaction resource
      #   response = client.wallets.eth_send_transaction(
      #     'wallet_id_123',
      #     transaction_params,
      #     caip2: 'eip155:11155111',
      #     return_resource: true
      #   )
      #   if response.is_a?(Privy::Resources::Transaction)
      #     puts "Transaction hash: #{response.hash}"
      #   end
      #
      def eth_send_transaction(wallet_id, transaction_params, caip2:, sponsor: nil, chain_type: 'ethereum', address: nil, authorization_signature: nil, authorization_context: nil, return_resource: false)
        # Validate inputs
        raise ArgumentError, 'wallet_id cannot be nil or empty' if wallet_id.nil? || wallet_id.to_s.strip.empty?
        raise ArgumentError, 'transaction_params must be a hash' unless transaction_params.is_a?(Hash)
        raise ArgumentError, 'transaction_params must include a transaction key' unless transaction_params.key?(:transaction) || transaction_params.key?('transaction')

        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        params = {
          method: 'eth_sendTransaction',
          caip2: caip2,
          chain_type: chain_type,
          params: transaction_params
        }

        # Add optional parameters if provided
        params[:sponsor] = sponsor unless sponsor.nil?
        params[:address] = address unless address.nil?

        response = request(:post, "wallets/#{wallet_id}/rpc", params, authorization_signature: authorization_signature, authorization_context: authorization_context)

        # Return Transaction resource if requested and successful
        if return_resource && response.success?
          Privy::Resources::Transaction.from_eth_send_transaction_response(response.data)
        else
          response
        end
      end

      # Sign a hash using the secp256k1 method
      #
      # @param wallet_id [String] The wallet ID to sign with
      # @param hash [String] The hash to sign in hex format (e.g., '0x12345678')
      # @param authorization_signature [String] Optional pre-computed signature
      # @param authorization_context [AuthorizationContext] Optional authorization context
      #
      # @return [Privy::Client::Response] Response containing the signature details
      #
      # @example Sign a hash
      #   response = client.wallets.secp256k1_sign(
      #     'wallet_id_123',
      #     '0x12345678'
      #   )
      #   if response.success?
      #     puts "Signature: #{response.data['data']['signature']}"
      #   end
      #
      def secp256k1_sign(wallet_id, hash, authorization_signature: nil, authorization_context: nil)
        # Validate inputs
        raise ArgumentError, 'wallet_id cannot be nil or empty' if wallet_id.nil? || wallet_id.to_s.strip.empty?
        raise ArgumentError, 'hash cannot be nil or empty' if hash.nil? || hash.to_s.strip.empty?

        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        params = {
          method: 'secp256k1_sign',
          params: {
            hash: hash
          }
        }

        request(:post, "wallets/#{wallet_id}/rpc", params, authorization_signature: authorization_signature, authorization_context: authorization_context)
      end

      # Signs an EIP-7702 authorization struct using the wallet's private key
      #
      # @param wallet_id [String] The wallet ID to sign with
      # @param contract [String] The address of the smart contract that the EOA will delegate to. Must be a valid Ethereum address in hex format.
      # @param chain_id [Integer] The chain ID where this authorization will be valid.
      # @param nonce [Integer] The nonce for the authorization. If not provided, defaults to 0.
      # @param authorization_signature [String] Optional pre-computed signature
      # @param authorization_context [AuthorizationContext] Optional authorization context
      #
      # @return [Privy::Client::Response] Response containing the signed EIP-7702 authorization
      #
      # @example Sign an EIP-7702 authorization
      #   response = client.wallets.eth_sign7702Authorization(
      #     'wallet_id_123',
      #     '0x1234567890abcdef1234567890abcdef12345678',
      #     1,
      #     nonce: 0
      #   )
      #   if response.success?
      #     auth = response.data['data']['authorization']
      #     puts "Signed authorization: #{auth}"
      #   end
      #
      def eth_sign7702Authorization(wallet_id, contract, chain_id, nonce: 0, authorization_signature: nil, authorization_context: nil)
        # Validate inputs
        raise ArgumentError, 'wallet_id cannot be nil or empty' if wallet_id.nil? || wallet_id.to_s.strip.empty?
        raise ArgumentError, 'contract cannot be nil or empty' if contract.nil? || contract.to_s.strip.empty?
        raise ArgumentError, 'chain_id cannot be nil' if chain_id.nil?

        # Use default authorization context from client if none provided
        authorization_context ||= @client.default_authorization_context

        params = {
          method: 'eth_sign7702Authorization',
          params: {
            contract: contract,
            chain_id: chain_id,
            nonce: nonce
          }
        }

        request(:post, "wallets/#{wallet_id}/rpc", params, authorization_signature: authorization_signature, authorization_context: authorization_context)
      end
    end
  end
end