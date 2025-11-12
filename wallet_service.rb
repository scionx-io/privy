# frozen_string_literal: true

require_relative 'lib/privy'

module Privy
  class WalletService
    attr_reader :api_client

    def initialize
      @app_id = Rails.application.credentials.privy_api_id
      @app_secret = Rails.application.credentials.privy_api_secret
      validate_credentials!
      @api_client = ::Privy::Client.new(app_id: @app_id, app_secret: @app_secret)
    end

    def create_wallet(params, idempotency_key: nil)
      response = api_client.wallets.create(params, idempotency_key: idempotency_key)
      handle_response(response)
    end

    def wallet(wallet_id)
      response = api_client.wallets.retrieve(wallet_id)
      handle_response(response)
    end

    def wallets
      response = api_client.wallets.list
      handle_response(response)
    end

    def balance(wallet_id)
      response = api_client.wallets.balance(wallet_id)
      handle_response(response)
    end

    def transactions(wallet_id)
      response = api_client.wallets.transactions(wallet_id)
      handle_response(response)
    end

    private

    def validate_credentials!
      return if @app_id.present? && @app_secret.present?

      raise ConfigurationError,
            "Privy API credentials (privy_api_id, privy_api_secret) are not configured in Rails credentials."
    end

    def handle_response(response)
      if response.success?
        response.data
      else
        Rails.logger.error("Privy API error: #{response.error.message}")
        raise ClientError, "API request failed: #{response.error.message}"
      end
    end
  end

  class ClientError < StandardError; end
  class ConfigurationError < StandardError; end
end
