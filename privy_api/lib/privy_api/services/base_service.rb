module PrivyApi
  module Services
    class BaseService
      def initialize(client)
        @client = client
      end

      protected

      def request(method, endpoint, params = {}, idempotency_key: nil)
        @client.send(:request, method, endpoint, params, idempotency_key: idempotency_key)
      end
    end
  end
end