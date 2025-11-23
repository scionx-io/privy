module Privy
  module Resources
    class DisplayValues < ApiResource
      # Nested resource for display values (usd, usdc, etc.)
    end

    class Balance < ApiResource
      def initialize(attributes = {})
        # Convert display_values hash to a resource for method access
        if attributes['display_values'].is_a?(Hash)
          attributes['display_values'] = DisplayValues.new(attributes['display_values'])
        end
        super(attributes)
      end
    end
  end
end