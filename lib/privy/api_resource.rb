module Privy
  class ApiResource < BaseResource
    extend ApiOperations::ClassMethods

    # This class serves as a base for API resources
    # Subclasses should define OBJECT_NAME constant
  end
end