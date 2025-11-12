module Privy
  module Models
    class BalancesCollection < ListObject
      def initialize(attributes = {})
        # Handle the response structure which has a 'balances' array
        if attributes.is_a?(Hash)
          balances_data = attributes[:balances] || attributes['balances'] || attributes[:data] || attributes['data'] || []
        else
          balances_data = attributes
        end

        # Convert each balance data to Balance instances
        balances = balances_data.map do |balance_data|
          if balance_data.is_a?(Hash)
            # Check if this looks like a balance object
            if likely_balance?(balance_data)
              Resources::Balance.construct_from(balance_data)
            else
              BaseResource.construct_from(balance_data)
            end
          else
            balance_data
          end
        end

        super(data: balances)
      end

      private

      def likely_balance?(hash)
        # A balance object typically has these keys
        required_keys = ['chain', 'asset', 'raw_value']
        required_keys.all? { |key| hash.key?(key) }
      end
    end
  end
end