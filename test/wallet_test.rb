# frozen_string_literal: true

require_relative 'privy_test'

class WalletTest < PrivyTest
  def test_retrieve_wallet_successfully
    wallet_id = 'wallet_test_123'
    
    stub_api_request(:get, "wallets/#{wallet_id}",
      body: { id: wallet_id, address: '0x789', chain_type: 'ethereum', created_at: '2023-01-01T00:00:00Z' }.to_json)

    response = @client.wallets.retrieve(wallet_id)

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal wallet_id, response.data.id
    assert_equal '0x789', response.data.address
  end

  def test_get_wallet_balance_successfully
    wallet_id = 'wallet_test_123'
    
    stub_request(:get, "https://api.privy.io/api/v1/wallets/#{wallet_id}/balance")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        query: { chain: 'ethereum', asset: 'eth' }
      )
      .to_return(
        status: 200,
        body: { chain: 'ethereum', asset: 'eth', raw_value: '1000000000000000000', display_value: '1.0' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.balance(wallet_id, { chain: 'ethereum', asset: 'eth' })

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'ethereum', response.data.chain
    assert_equal 'eth', response.data.asset
  end

  def test_get_wallet_transactions_successfully
    wallet_id = 'wallet_test_123'
    
    stub_request(:get, "https://api.privy.io/api/v1/wallets/#{wallet_id}/transactions")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        query: { chain: 'ethereum', asset: 'eth' }
      )
      .to_return(
        status: 200,
        body: { transactions: [{ transaction_hash: '0xabc', status: 'confirmed', created_at: '2023-01-01T00:00:00Z' }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.transactions(wallet_id, { chain: 'ethereum', asset: 'eth' })

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'confirmed', response.data.first.status
  end
end