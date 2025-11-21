# frozen_string_literal: true

module Privy
  # Base error class for all Privy API errors
  class ApiError < StandardError; end

  # Raised when authentication fails (401)
  class AuthenticationError < ApiError; end

  # Raised when rate limit is exceeded (429)
  class RateLimitError < ApiError; end

  # Raised when access is forbidden (403)
  class ForbiddenError < ApiError; end

  # Raised when a resource is not found (404)
  class NotFoundError < ApiError; end

  # Raised when the service is unavailable (503)
  class ServiceUnavailableError < ApiError; end

  # Raised when there's an internal server error (500)
  class ServerError < ApiError; end

  # Raised when authorization/signing fails
  class AuthorizationError < ApiError; end

  # Raised when HPKE operations fail
  class HpkeError < StandardError; end
end
