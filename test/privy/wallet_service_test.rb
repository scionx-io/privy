# frozen_string_literal: true

require_relative '../privy_test'
require 'minitest/autorun'
require 'ostruct'

module Privy
  module Services
    class WalletServiceTest < Minitest::Test
      def setup
        @client = Privy::Client.new(
          app_id: 'test_app_id',
          app_secret: 'test_app_secret'
        )
        @service = @client.wallets
      end

      def test_balance_returns_array_of_balance_objects
        # Mock the HTTP response
        mock_response = {
          'balances' => [
            {
              'chain' => 'arbitrum',
              'asset' => 'usdc',
              'raw_value' => '1000000',
              'raw_value_decimals' => 6,
              'display_values' => {
                'usdc' => '1.0',
                'usd' => '1.00'
              }
            }
          ]
        }

        # Stub the request method to return mock response
        @client.stub :request, Privy::Client::Response.new(200, Util::PrivyObject.new(mock_response), nil) do
          result = @service.balance('wallet_123')

          # Should return Response with array of Balance objects
          assert result.success?
          assert_instance_of Array, result.data
          assert_instance_of Privy::Resources::Balance, result.data.first
        end
      end
    end
  end
end