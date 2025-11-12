module Privy
  module Resources
    class Wallet < ApiResource
      extend ApiOperations::Crud
      extend ApiOperations::Custom
      include ApiOperations::ClassMethods

      # Define the resource path
      self.resource_path = 'wallets'

      # Add custom operations specific to wallets
      define_custom_operation :balance, :get, 'wallets/:id/balance'
      define_custom_operation :transactions, :get, 'wallets/:id/transactions'
    end
  end
end