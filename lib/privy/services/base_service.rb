module Privy
  module Services
    class BaseService
      def initialize(client)
        @client = client
      end

      protected

      def request(method, endpoint, params = {}, idempotency_key: nil, authorization_signature: nil, authorization_context: nil)
        @client.send(:request, method, endpoint, params, idempotency_key: idempotency_key, authorization_signature: authorization_signature, authorization_context: authorization_context)
      end
    end
  end
end