module PrivyApi
  module Models
    class TransactionsCollection < ListObject
      def initialize(attributes = {})
        # Handle the response structure which has a 'transactions' array and 'next_cursor'
        if attributes.is_a?(Hash)
          transactions_data = attributes[:transactions] || attributes['transactions'] || attributes[:data] || attributes['data'] || []
          @next_cursor = attributes[:next_cursor] || attributes['next_cursor']
          @has_more = !@next_cursor.nil?
        else
          transactions_data = attributes
          @next_cursor = nil
          @has_more = false
        end

        # Convert each transaction data to Transaction instances
        transactions = transactions_data.map do |transaction_data|
          if transaction_data.is_a?(Hash)
            # Check if this looks like a transaction object
            if likely_transaction?(transaction_data)
              Resources::Transaction.construct_from(transaction_data)
            else
              BaseResource.construct_from(transaction_data)
            end
          else
            transaction_data
          end
        end

        super(data: transactions)
      end

      attr_reader :next_cursor

      private

      def likely_transaction?(hash)
        # A transaction object typically has these keys
        required_keys = ['transaction_hash', 'status', 'created_at']
        required_keys.all? { |key| hash.key?(key) }
      end
    end
  end
end