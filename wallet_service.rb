# frozen_string_literal: true

module Privy
  class WalletService
    BASE_URL = "https://api.privy.io/api/v1"

    attr_reader :app_id, :api_client

    def initialize
      @app_id = Rails.application.credentials.privy_api_id
      @app_secret = Rails.application.credentials.privy_api_secret
      validate_credentials!
      @api_client = build_api_client
    end

    def create_wallet(params, idempotency_key: nil)
      headers = idempotency_key ? { "privy-idempotency-key" => idempotency_key } : {}
      make_request(:post, "wallets", params, headers)
    end

    def wallet(wallet_id)
      make_request(:get, "wallets/#{wallet_id}")
    end

    def wallets
      make_request(:get, "wallets")
    end

    def balance(wallet_id)
      make_request(:get, "wallets/#{wallet_id}/balance")
    end

    def transactions(wallet_id)
      make_request(:get, "wallets/#{wallet_id}/transactions")
    end

    private

    def validate_credentials!
      return if @app_id.present? && @app_secret.present?

      raise ConfigurationError,
            "Privy API credentials (privy_api_id, privy_api_secret) are not configured in Rails credentials."
    end

    def build_api_client
      Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.headers["User-Agent"] = "ScionX/1.0 Ruby/Privy-Client"
        f.headers["Content-Type"] = "application/json"
        f.headers["privy-app-id"] = @app_id
        f.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{@app_id}:#{@app_secret}")}"
        f.adapter Faraday.default_adapter
      end
    end

    def make_request(method, path, body = nil, headers = {})
      response = api_client.send(method, path) do |req|
        headers.each { |k, v| req.headers[k] = v }
        req.body = body if body
      end
      handle_response(response)
    rescue StandardError => e
      Rails.logger.error("Privy API #{method.upcase} error for #{path}: #{e.message}")
      raise ClientError, "#{method.upcase} request failed: #{e.message}"
    end

    def handle_response(response)
      case response.status
      when 200..299 then response.body
      when 400..499 then raise ClientError, error_message(response, "Client error")
      when 500..599 then raise ClientError, error_message(response, "Server error")
      else raise ClientError, "Unexpected response status: #{response.status}"
      end
    end

    def error_message(response, fallback)
      extract_error_message(response.body) || "#{fallback} (#{response.status})"
    end

    def extract_error_message(body)
      parsed = parse_body(body)
      return parsed if parsed.is_a?(String)
      return nil unless parsed.is_a?(Hash)

      parsed[:message] || parsed[:error] || parsed["message"] || parsed["error"]
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end

  class ClientError < StandardError; end
  class ConfigurationError < StandardError; end
end
