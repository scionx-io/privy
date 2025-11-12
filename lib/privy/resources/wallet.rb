module Privy
  module Resources
    class Wallet < ApiResource
      def self.list(params = {}, client: nil)
        client ||= Privy::Client.new
        client.request(:get, 'wallets', params)
      end

      def self.retrieve(wallet_id, params = {}, client: nil)
        client ||= Privy::Client.new
        client.request(:get, "wallets/#{wallet_id}", params)
      end

      def self.create(params = {}, idempotency_key: nil, client: nil)
        client ||= Privy::Client.new
        client.request(:post, 'wallets', params, idempotency_key: idempotency_key)
      end

      def self.balance(wallet_id, params = {}, client: nil)
        client ||= Privy::Client.new
        client.request(:get, "wallets/#{wallet_id}/balance", params)
      end

      def self.transactions(wallet_id, params = {}, client: nil)
        client ||= Privy::Client.new
        client.request(:get, "wallets/#{wallet_id}/transactions", params)
      end
    end
  end
end