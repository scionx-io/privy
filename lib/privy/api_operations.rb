module Privy
  module ApiOperations
    module ClassMethods
      def resource_path=(path)
        @resource_path = path
      end

      def resource_path
        @resource_path
      end

      def define_custom_operation(name, method, path_template)
        define_singleton_method(name) do |*args, client: nil|
          client ||= Privy::Client.new
          id = args.first # First argument is typically the ID
          
          # Replace :id in path template with actual ID
          path = path_template.gsub(':id', id.to_s)
          
          case method
          when :get
            client.request(:get, path, args[1] || {}) # Second argument is params
          when :post
            client.request(:post, path, args[1] || {}) # Second argument is params
          when :put
            client.request(:put, path, args[1] || {}) # Second argument is params
          when :delete
            client.request(:delete, path, args[1] || {}) # Second argument is params
          end
        end
      end
    end

    module Crud
      def self.extended(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def list(params = {}, client: nil)
          client ||= Privy::Client.new
          client.request(:get, resource_path, params)
        end

        def retrieve(id, params = {}, client: nil)
          client ||= Privy::Client.new
          client.request(:get, "#{resource_path}/#{id}", params)
        end

        def create(params = {}, idempotency_key: nil, client: nil)
          client ||= Privy::Client.new
          client.request(:post, resource_path, params, idempotency_key: idempotency_key)
        end
      end
    end

    module Custom
      def self.extended(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Methods for custom operations like balance, transactions
      end
    end
  end
end