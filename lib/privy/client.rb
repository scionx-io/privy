# frozen_string_literal: true

require 'httparty'
require 'securerandom'
require 'json'
require 'base64'

module Privy
  class Client
    include HTTParty

    BASE_URL = 'https://api.privy.io/api/v1'.freeze
    DEFAULT_TIMEOUT = 30

    def initialize(app_id: nil, app_secret: nil)
      @app_id = app_id || Privy.app_id
      @app_secret = app_secret || Privy.app_secret
      validate_credentials!

      configure_client
    end

    def wallets
      @wallets_service ||= Services::WalletService.new(self)
    end

    private

    def validate_credentials!
      raise ArgumentError, 'App ID must be provided' if @app_id.to_s.strip.empty?
      raise ArgumentError, 'App Secret must be provided' if @app_secret.to_s.strip.empty?
    end

    def configure_client
      self.class.base_uri(BASE_URL)
      self.class.default_timeout(DEFAULT_TIMEOUT)
      
      # Create the authorization header using basic auth
      credentials = Base64.strict_encode64("#{@app_id}:#{@app_secret}")
      
      self.class.headers(
        'Authorization' => "Basic #{credentials}",
        'Content-Type' => 'application/json',
        'User-Agent' => 'PrivyApi Ruby Client',
        'privy-app-id' => @app_id
      )
    end

    def request(method, endpoint, payload = {}, idempotency_key: nil)
      options = build_request_options(method, payload, idempotency_key: idempotency_key)
      response = self.class.send(method, "/#{endpoint}", options)

      handle_response(response)
    end

    def build_request_options(method, payload, idempotency_key: nil)
      if method == :get
        { query: payload }
      else
        headers = {}
        headers['privy-idempotency-key'] = idempotency_key if idempotency_key
        { body: payload.to_json, headers: headers }
      end
    end

    def handle_response(response)
      status = response.code
      success = (200..299).cover?(status)

      raw_data = success ? response.parsed_response : nil
      data = raw_data ? Util.convert_to_bridged_object(raw_data) : nil
      error = success ? nil : build_error(status, response)

      Response.new(status, data, error)
    end

    def build_error(status, response)
      msg = extract_error_message(response.parsed_response)

      case status
      when 400 then ApiError.new(msg || 'Bad request')
      when 401 then AuthenticationError.new(msg || 'Invalid App credentials')
      when 403 then ForbiddenError.new(msg || 'Forbidden')
      when 404 then NotFoundError.new('Resource not found')
      when 429 then RateLimitError.new('Rate limit exceeded')
      when 500 then ServerError.new(msg || 'Internal server error')
      when 503 then ServiceUnavailableError.new('Service temporarily unavailable')
      else ApiError.new(msg || "API request failed (status: #{status})")
      end
    end

    def extract_error_message(parsed_response)
      return nil unless parsed_response.is_a?(Hash)

      parsed_response['message'] || parsed_response['error'] || parsed_response.dig('error', 'message')
    end

    # Response wrapper class
    class Response
      attr_reader :status_code, :data, :error

      def initialize(status_code, data, error)
        @status_code = status_code
        @data = data
        @error = error
      end

      def success?
        @error.nil?
      end

      def failure?
        !success?
      end
    end
  end

  # Error classes
  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end
  class RateLimitError < ApiError; end
  class ForbiddenError < ApiError; end
  class NotFoundError < ApiError; end
  class ServiceUnavailableError < ApiError; end
  class ServerError < ApiError; end
end