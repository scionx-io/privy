module PrivyApi
  module Util
    extend self

    def convert_to_bridged_object(data)
      case data
      when Hash
        convert_hash(data)
      when Array
        # If it's an array of wallet-like objects, wrap in WalletsCollection
        if data.all? { |item| item.is_a?(Hash) && likely_wallet?(item) }
          Models::WalletsCollection.new(data)
        else
          data.map { |item| convert_to_bridged_object(item) }
        end
      else
        data
      end
    end

    private

    def convert_hash(hash)
      return BaseResource.new(hash) unless hash.is_a?(Hash)

      # Create a mapping of object types to resource classes
      object_type = hash['object'] || hash[:object]

      case object_type
      when 'wallet'
        Resources::Wallet.construct_from(hash)
      when 'transaction'
        Resources::Transaction.construct_from(hash)
      when 'balance'
        Resources::Balance.construct_from(hash)
      else
        # Check if this is a balances response (has a 'balances' key with an array)
        if hash.key?('balances') && hash['balances'].is_a?(Array)
          # This is a balances response
          Models::BalancesCollection.new(hash)
        # Check if this is a transactions response (has a 'transactions' key with an array)
        elsif hash.key?('transactions') && hash['transactions'].is_a?(Array)
          # This is a transactions response
          Models::TransactionsCollection.new(hash)
        # Check if this looks like a list response (has a 'data' key with an array)
        elsif hash.key?('data') && hash['data'].is_a?(Array)
          # This might be a paginated response
          if hash['data'].all? { |item| item.is_a?(Hash) && likely_wallet?(item) }
            Models::WalletsCollection.new(hash)
          else
            BaseResource.construct_from(hash)
          end
        else
          # Return as generic BaseResource if no specific type
          BaseResource.construct_from(hash)
        end
      end
    end

    # Heuristic to determine if a hash looks like a wallet object
    def likely_wallet?(hash)
      required_keys = ['id', 'address', 'chain_type']
      required_keys.all? { |key| hash.key?(key) }
    end

    # Heuristic to determine if a hash looks like a balance object
    def likely_balance?(hash)
      required_keys = ['chain', 'asset', 'raw_value']
      required_keys.all? { |key| hash.key?(key) }
    end

    # Heuristic to determine if a hash looks like a transaction object
    def likely_transaction?(hash)
      required_keys = ['transaction_hash', 'status', 'created_at']
      required_keys.all? { |key| hash.key?(key) }
    end
  end
end