module Privy
  module Resources
    class Transaction < ApiResource
      # Transaction resource class
      # This will automatically have dynamic methods created by BaseResource

      # Create a Transaction resource from eth_send_transaction API response
      # The API returns: { method: 'eth_sendTransaction', data: { hash: '...', caip2: '...', transaction_id: '...' } }
      def self.from_eth_send_transaction_response(api_response)
        # Extract the transaction data from the nested structure
        transaction_data = api_response.is_a?(Hash) ? api_response['data'] : api_response.data
        new(transaction_data)
      end

      def hash
        self[:hash] || self['hash']
      end

      def caip2
        self[:caip2] || self['caip2']
      end

      def transaction_id
        self[:transaction_id] || self['transaction_id']
      end

      # Dynamic method handling for all attributes
      def method_missing(method_name, *args)
        if respond_to?(method_name)
          self[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        to_hash.key?(method_name.to_sym) || super
      end
    end
  end
end