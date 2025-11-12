# frozen_string_literal: true

require_relative 'privy_test'

class ClientTest < PrivyTest
  def test_list_wallets_successfully
    stub_api_request(:get, 'wallets',
      body: { data: [{ id: 'wallet_1', address: '0x123', chain_type: 'ethereum' }] }.to_json)

    response = @client.wallets.list

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'wallet_1', response.data.first.id
  end

  def test_create_wallet_successfully
    stub_api_request(:post, 'wallets',
      headers: { 'privy-idempotency-key' => 'test-key-123' },
      status: 201,
      body: { id: 'wallet_new', address: '0x456', chain_type: 'ethereum' }.to_json)

    response = @client.wallets.create({ chain_type: 'ethereum' }, idempotency_key: 'test-key-123')

    assert response.success?
    assert_equal 201, response.status_code
    assert_equal 'wallet_new', response.data.id
  end

  def test_handle_authentication_errors
    stub_api_request(:get, 'wallets',
      status: 401,
      body: { error: 'Invalid credentials' }.to_json)

    response = @client.wallets.list

    refute response.success?
    assert_equal 401, response.status_code
    assert_instance_of Privy::AuthenticationError, response.error
  end
end