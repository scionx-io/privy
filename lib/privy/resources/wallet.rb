module Privy
  module Resources
    class Wallet < BaseResource
      # Specific accessor methods for convenience
      def id
        self[:id]
      end

      def address
        self[:address]
      end

      def chain_type
        self[:chain_type]
      end

      def created_at
        self[:created_at]
      end

      def updated_at
        self[:updated_at]
      end

      # Dynamic method handling for all attributes
      def method_missing(method_name, *args)
        if respond_to?(method_name)
          self[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        to_hash.key?(method_name.to_sym) || super
      end
    end
  end
end