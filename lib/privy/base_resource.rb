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
        # Create a getter method for each attribute
        # Only allow valid Ruby instance variable names
        safe_attr_name = validate_and_sanitize_attr_name(key.to_s)
        next if safe_attr_name.nil? # Skip invalid attribute names

        instance_variable_set("@#{safe_attr_name}", value)
        self.class.define_method(attr_name) { instance_variable_get("@#{safe_attr_name}") }
      end
    end

    def to_hash
      instance_variables.to_h do |var|
        # Remove @ and convert back to symbol, but be careful with validation
        var_name = var.to_s.delete('@')
        # Only convert valid variable names back to symbols
        key = var_name.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/) ? var_name.to_sym : var_name
        [key, instance_variable_get(var)]
      end
    end

    def [](key)
      attr_name = key.to_s.to_sym
      send(attr_name) if respond_to?(attr_name)
    end

    def respond_to_missing?(method_name, include_private = false)
      # Check if the method name corresponds to an instance variable
      attr_name = validate_and_sanitize_attr_name(method_name.to_s)
      if attr_name
        instance_variable_defined?("@#{attr_name}") || super
      else
        super
      end
    end

    private

    def validate_and_sanitize_attr_name(name_str)
      # Check if the name is already valid as an instance variable name
      if name_str.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
        # Valid name, can be used as-is
        name_str
      else
        # Sanitize the name to make it valid
        sanitized = name_str.gsub(/[^a-zA-Z0-9_]/, '_')
        # Must start with letter or underscore
        if sanitized.match?(/^[a-zA-Z_]/)
          sanitized
        else
          "_#{sanitized}" # prefix with underscore if it doesn't start properly
        end
      end
    end
  end
end