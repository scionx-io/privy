module Privy
  class BaseResource
    def self.construct_from(values)
      new(values)
    end

    def initialize(attributes = {})
      return unless attributes

      attributes.each do |key, value|
        # Ensure key is a symbol for consistency
        attr_name = key.to_s.to_sym
        instance_variable_set("@#{attr_name}", value)
        # Create a getter method for each attribute
        self.class.define_method(attr_name) { instance_variable_get("@#{attr_name}") }
      end
    end

    def to_hash
      instance_variables.to_h do |var|
        [var.to_s.delete('@').to_sym, instance_variable_get(var)]
      end
    end

    def [](key)
      attr_name = key.to_s.to_sym
      send(attr_name) if respond_to?(attr_name)
    end

    def respond_to_missing?(method_name, include_private = false)
      instance_variable_defined?("@#{method_name}") || super
    end
  end
end