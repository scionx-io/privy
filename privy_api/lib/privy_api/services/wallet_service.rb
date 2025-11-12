module PrivyApi
  module Services
    class WalletService < BaseService
      def create(params = {}, idempotency_key: nil)
        request(:post, 'wallets', params, idempotency_key: idempotency_key)
      end

      def retrieve(wallet_id, params = {})
        request(:get, "wallets/#{wallet_id}", params)
      end

      def list(params = {})
        request(:get, 'wallets', params)
      end

      def balance(wallet_id, params = {})
        request(:get, "wallets/#{wallet_id}/balance", params)
      end

      def transactions(wallet_id, params = {})
        request(:get, "wallets/#{wallet_id}/transactions", params)
      end
    end
  end
end