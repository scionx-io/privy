module PrivyApi
  module Models
    class WalletsCollection < ListObject
      def initialize(attributes = {})
        # Handle both array and hash with data key
        if attributes.is_a?(Array)
          wallets_data = attributes
        elsif attributes.is_a?(Hash)
          wallets_data = attributes[:data] || attributes['data'] || attributes
        else
          wallets_data = []
        end

        # Convert each wallet data to Wallet instances
        wallets = wallets_data.map do |wallet_data|
          if wallet_data.is_a?(Hash)
            Resources::Wallet.construct_from(wallet_data)
          else
            wallet_data
          end
        end

        super(data: wallets)
      end
    end
  end
end