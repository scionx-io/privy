# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/minitest'
require_relative '../lib/privy'

# Base test class with common setup
class PrivyTest < Minitest::Test
  def setup
    @app_id = 'test_app_id'
    @app_secret = 'test_app_secret'
    @client = Privy::Client.new(app_id: @app_id, app_secret: @app_secret)
    @auth_header = 'Basic ' + Base64.strict_encode64("#{@app_id}:#{@app_secret}")
  end

  def stub_api_request(method, path, opts = {})
    stub_request(method, "https://api.privy.io/api/v1/#{path}")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        }.merge(opts[:headers] || {})
      )
      .to_return(
        status: opts[:status] || 200,
        body: opts[:body] || {}.to_json,
        headers: opts[:response_headers] || { 'Content-Type' => 'application/json' }
      )
  end
end