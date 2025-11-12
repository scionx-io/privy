# PrivyApi

A Ruby gem for integrating with the Privy API for wallet management and authentication services.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'privy_api'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install privy_api
```

## Usage

### Configuration

```ruby
PrivyApi.config do |c|
  c.app_id = 'your-app-id'
  c.app_secret = 'your-app-secret'
end
```

### Creating a Client

```ruby
client = PrivyApi::Client.new
# or with explicit credentials
client = PrivyApi::Client.new(app_id: 'your-app-id', app_secret: 'your-app-secret')
```

### Wallet Operations

#### List Wallets
```ruby
response = client.wallets.list
if response.success?
  response.data.each do |wallet|
    puts "Wallet: #{wallet}"
  end
else
  puts "Error: #{response.error.message}"
end
```

#### Create a Wallet
```ruby
response = client.wallets.create({ chain: 'ethereum' }, idempotency_key: 'unique-key-123')
if response.success?
  puts "Wallet created: #{response.data}"
else
  puts "Error: #{response.error.message}"
end
```

#### Get Wallet Details
```ruby
response = client.wallets.retrieve('wallet-id')
if response.success?
  puts "Wallet details: #{response.data}"
else
  puts "Error: #{response.error.message}"
end
```

#### Get Wallet Balance
```ruby
response = client.wallets.balance('wallet-id')
if response.success?
  puts "Balance: #{response.data}"
else
  puts "Error: #{response.error.message}"
end
```

#### Get Wallet Transactions
```ruby
response = client.wallets.transactions('wallet-id')
if response.success?
  puts "Transactions: #{response.data}"
else
  puts "Error: #{response.error.message}"
end
```

### Using Resources Directly

```ruby
# List wallets
wallets = PrivyApi::Resources::Wallet.list

# Create wallet
wallet = PrivyApi::Resources::Wallet.create({ chain: 'ethereum' })

# Get wallet
wallet = PrivyApi::Resources::Wallet.retrieve('wallet-id')

# Get wallet balance
balance = PrivyApi::Resources::Wallet.balance('wallet-id')

# Get wallet transactions
transactions = PrivyApi::Resources::Wallet.transactions('wallet-id')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ScionX/privy_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).