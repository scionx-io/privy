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
    assert_equal 'confirmed', response.data['transactions'][0]['status']
  end

  def test_eth_send_transaction_successfully
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'eth_sendTransaction',
          caip2: 'eip155:11155111',
          chain_type: 'ethereum',
          params: transaction_params,
          sponsor: true
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sendTransaction',
          data: {
            hash: '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8',
            caip2: 'eip155:11155111',
            transaction_id: 'y90vpg3bnkjxhw541c2zc6a9'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111',
      sponsor: true
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'eth_sendTransaction', response.data['method']
    assert_equal '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8', response.data['data']['hash']
    assert_equal 'eip155:11155111', response.data['data']['caip2']
    assert_equal 'y90vpg3bnkjxhw541c2zc6a9', response.data['data']['transaction_id']
  end

  def test_eth_send_transaction_without_sponsor
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'eth_sendTransaction',
          caip2: 'eip155:1',
          chain_type: 'ethereum',
          params: transaction_params
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sendTransaction',
          data: {
            hash: '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8',
            caip2: 'eip155:1',
            transaction_id: 'y90vpg3bnkjxhw541c2zc6a9'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:1'
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'eth_sendTransaction', response.data['method']
  end

  def test_eth_send_transaction_with_404_error
    wallet_id = 'nonexistent_wallet'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 404,
        body: { error: 'Wallet not found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111'
    )

    assert response.failure?
    assert_equal 404, response.status_code
    assert response.error
  end

  def test_eth_send_transaction_with_400_error
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: 'invalid_address',
        value: '0xinvalid'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 400,
        body: { error: 'Invalid transaction parameters' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111'
    )

    assert response.failure?
    assert_equal 400, response.status_code
    assert response.error
  end

  def test_eth_send_transaction_with_401_error
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 401,
        body: { error: 'Unauthorized' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111'
    )

    assert response.failure?
    assert_equal 401, response.status_code
    assert response.error
  end

  def test_eth_send_transaction_with_429_error
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 429,
        body: { error: 'Rate limit exceeded' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111'
    )

    assert response.failure?
    assert_equal 429, response.status_code
    assert response.error
  end

  def test_eth_send_transaction_with_authorization_signature
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }
    auth_signature = 'test-authorization-signature'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id,
          'privy-authorization-signature' => auth_signature
        },
        body: {
          method: 'eth_sendTransaction',
          caip2: 'eip155:11155111',
          chain_type: 'ethereum',
          params: transaction_params
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sendTransaction',
          data: {
            hash: '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8',
            caip2: 'eip155:11155111',
            transaction_id: 'y90vpg3bnkjxhw541c2zc6a9'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111',
      authorization_signature: auth_signature
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'eth_sendTransaction', response.data['method']
  end

  def test_eth_send_transaction_resource_return
    wallet_id = 'wallet_test_123'
    transaction_params = {
      transaction: {
        to: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        value: '0x2386F26FC10000'
      }
    }

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'eth_sendTransaction',
          caip2: 'eip155:11155111',
          chain_type: 'ethereum',
          params: transaction_params
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sendTransaction',
          data: {
            hash: '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8',
            caip2: 'eip155:11155111',
            transaction_id: 'y90vpg3bnkjxhw541c2zc6a9'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @client.wallets.eth_send_transaction(
      wallet_id,
      transaction_params,
      caip2: 'eip155:11155111',
      return_resource: true
    )

    assert_instance_of Privy::Resources::Transaction, result
    assert_equal '0xfc3a736ab2e34e13be2b0b11b39dbc0232a2e755a11aa5a9219890d3b2c6c7d8', result.hash
    assert_equal 'eip155:11155111', result.caip2
    assert_equal 'y90vpg3bnkjxhw541c2zc6a9', result.transaction_id
  end

  def test_secp256k1_sign_successfully
    wallet_id = 'wallet_test_123'
    hash = '0x12345678'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'secp256k1_sign',
          params: { hash: hash }
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'secp256k1_sign',
          data: {
            signature: '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a64196e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae3081c',
            encoding: 'hex'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.secp256k1_sign(
      wallet_id,
      hash
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'secp256k1_sign', response.data['method']
    assert_equal '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a64196e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae3081c', response.data['data']['signature']
    assert_equal 'hex', response.data['data']['encoding']
  end

  def test_secp256k1_sign_with_authorization_signature
    wallet_id = 'wallet_test_123'
    hash = '0x12345678'
    auth_signature = 'test-authorization-signature'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id,
          'privy-authorization-signature' => auth_signature
        },
        body: {
          method: 'secp256k1_sign',
          params: { hash: hash }
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'secp256k1_sign',
          data: {
            signature: '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a64196e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae3081c',
            encoding: 'hex'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.secp256k1_sign(
      wallet_id,
      hash,
      authorization_signature: auth_signature
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'secp256k1_sign', response.data['method']
  end

  def test_secp256k1_sign_with_404_error
    wallet_id = 'nonexistent_wallet'
    hash = '0x12345678'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 404,
        body: { error: 'Wallet not found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.secp256k1_sign(
      wallet_id,
      hash
    )

    assert response.failure?
    assert_equal 404, response.status_code
    assert response.error
  end

  def test_secp256k1_sign_with_400_error
    wallet_id = 'wallet_test_123'
    hash = 'invalid_hash'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 400,
        body: { error: 'Invalid hash parameters' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.secp256k1_sign(
      wallet_id,
      hash
    )

    assert response.failure?
    assert_equal 400, response.status_code
    assert response.error
  end

  def test_secp256k1_sign_validation
    assert_raises(ArgumentError) do
      @client.wallets.secp256k1_sign(nil, '0x12345678')
    end

    assert_raises(ArgumentError) do
      @client.wallets.secp256k1_sign('', '0x12345678')
    end

    assert_raises(ArgumentError) do
      @client.wallets.secp256k1_sign('wallet_id', nil)
    end

    assert_raises(ArgumentError) do
      @client.wallets.secp256k1_sign('wallet_id', '')
    end

    assert_raises(ArgumentError) do
      @client.wallets.secp256k1_sign('wallet_id', '   ')
    end
  end

  def test_eth_sign7702Authorization_successfully
    wallet_id = 'wallet_test_123'
    contract = '0x1234567890abcdef1234567890abcdef12345678'
    chain_id = 1
    nonce = 0

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'eth_sign7702Authorization',
          params: {
            contract: contract,
            chain_id: chain_id,
            nonce: nonce
          }
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sign7702Authorization',
          data: {
            authorization: {
              contract: contract,
              chain_id: chain_id,
              nonce: nonce,
              r: '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a6419',
              s: '0x6e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae308',
              y_parity: 1
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract,
      chain_id,
      nonce: nonce
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'eth_sign7702Authorization', response.data['method']
    assert_equal contract, response.data['data']['authorization']['contract']
    assert_equal chain_id, response.data['data']['authorization']['chain_id']
    assert_equal nonce, response.data['data']['authorization']['nonce']
    assert_equal '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a6419', response.data['data']['authorization']['r']
    assert_equal '0x6e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae308', response.data['data']['authorization']['s']
    assert_equal 1, response.data['data']['authorization']['y_parity']
  end

  def test_eth_sign7702Authorization_with_default_nonce
    wallet_id = 'wallet_test_123'
    contract = '0x1234567890abcdef1234567890abcdef12345678'
    chain_id = 1

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id
        },
        body: {
          method: 'eth_sign7702Authorization',
          params: {
            contract: contract,
            chain_id: chain_id,
            nonce: 0  # Default nonce
          }
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sign7702Authorization',
          data: {
            authorization: {
              contract: contract,
              chain_id: chain_id,
              nonce: 0,
              r: '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a6419',
              s: '0x6e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae308',
              y_parity: 0
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract,
      chain_id
      # No nonce provided - should use default of 0
    )

    assert response.success?
    assert_equal 200, response.status_code
    # Verify that nonce 0 was used as default
    assert_equal 0, response.data['data']['authorization']['nonce']
  end

  def test_eth_sign7702Authorization_with_authorization_signature
    wallet_id = 'wallet_test_123'
    contract = '0x1234567890abcdef1234567890abcdef12345678'
    chain_id = 1
    nonce = 0
    auth_signature = 'test-authorization-signature'

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .with(
        headers: {
          'Authorization' => @auth_header,
          'Content-Type' => 'application/json',
          'privy-app-id' => @app_id,
          'privy-authorization-signature' => auth_signature
        },
        body: {
          method: 'eth_sign7702Authorization',
          params: {
            contract: contract,
            chain_id: chain_id,
            nonce: nonce
          }
        }.to_json
      )
      .to_return(
        status: 200,
        body: {
          method: 'eth_sign7702Authorization',
          data: {
            authorization: {
              contract: contract,
              chain_id: chain_id,
              nonce: nonce,
              r: '0x0db9c7bd881045cbba28c347de6cc32a653e15d7f6f2f1cec21d645f402a6419',
              s: '0x6e877eb45d3041f8d2ab1a76f57f408b63894cfc6f339d8f584bd26efceae308',
              y_parity: 1
            }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract,
      chain_id,
      nonce: nonce,
      authorization_signature: auth_signature
    )

    assert response.success?
    assert_equal 200, response.status_code
    assert_equal 'eth_sign7702Authorization', response.data['method']
  end

  def test_eth_sign7702Authorization_with_404_error
    wallet_id = 'nonexistent_wallet'
    contract = '0x1234567890abcdef1234567890abcdef12345678'
    chain_id = 1
    nonce = 0

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 404,
        body: { error: 'Wallet not found' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract,
      chain_id,
      nonce: nonce
    )

    assert response.failure?
    assert_equal 404, response.status_code
    assert response.error
  end

  def test_eth_sign7702Authorization_with_400_error
    wallet_id = 'wallet_test_123'
    contract = 'invalid_address'
    chain_id = 1
    nonce = 0

    stub_request(:post, "https://api.privy.io/api/v1/wallets/#{wallet_id}/rpc")
      .to_return(
        status: 400,
        body: { error: 'Invalid authorization parameters' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    response = @client.wallets.eth_sign7702Authorization(
      wallet_id,
      contract,
      chain_id,
      nonce: nonce
    )

    assert response.failure?
    assert_equal 400, response.status_code
    assert response.error
  end

  def test_eth_sign7702Authorization_validation
    # Test wallet_id validation
    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization(nil, '0x1234567890abcdef1234567890abcdef12345678', 1)
    end

    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('', '0x1234567890abcdef1234567890abcdef12345678', 1)
    end

    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('   ', '0x1234567890abcdef1234567890abcdef12345678', 1)
    end

    # Test contract validation
    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('wallet_id', nil, 1)
    end

    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('wallet_id', '', 1)
    end

    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('wallet_id', '   ', 1)
    end

    # Test chain_id validation
    assert_raises(ArgumentError) do
      @client.wallets.eth_sign7702Authorization('wallet_id', '0x1234567890abcdef1234567890abcdef12345678', nil)
    end
  end
end