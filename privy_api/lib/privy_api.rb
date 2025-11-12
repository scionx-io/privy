# frozen_string_literal: true

require 'httparty'
require 'json'
require 'securerandom'
require 'base64'

require_relative 'privy_api/version'
require_relative 'privy_api/base_resource'
require_relative 'privy_api/api_resource'
require_relative 'privy_api/api_operations'
require_relative 'privy_api/list_object'
require_relative 'privy_api/util'
require_relative 'privy_api/client'
require_relative 'privy_api/resources/wallet'
require_relative 'privy_api/resources/transaction'
require_relative 'privy_api/resources/balance'
require_relative 'privy_api/models/wallets_collection'
require_relative 'privy_api/models/transaction'
require_relative 'privy_api/models/transactions_collection'
require_relative 'privy_api/models/balance'
require_relative 'privy_api/models/balances_collection'
require_relative 'privy_api/services/base_service'
require_relative 'privy_api/services/wallet_service'

# Ruby gem for Privy API integration
#
# @example Basic usage
#   PrivyApi.configure do |config|
#     config.app_id = 'your-app-id'
#     config.app_secret = 'your-app-secret'
#   end
#
#   client = PrivyApi::Client.new
#   response = client.wallets.list
module PrivyApi
  class << self
    # @return [String, nil] Global App ID for Privy
    attr_accessor :app_id

    # @return [String, nil] Global App Secret for Privy
    attr_accessor :app_secret

    attr_writer :base_url

    # Configure global settings for Privy API
    #
    # @yieldparam config [PrivyApi] The module to configure
    #
    # @example
    #   PrivyApi.configure do |config|
    #     config.app_id = 'your-app-id'
    #     config.app_secret = 'your-app-secret'
    #   end
    def configure
      yield self
    end

    # @deprecated Use {configure} instead
    def config(&block)
      configure(&block)
    end

    # @return [String] The base URL for the API
    def base_url
      @base_url || default_base_url
    end

    private

    def default_base_url
      'https://api.privy.io/api/v1/'
    end
  end
end