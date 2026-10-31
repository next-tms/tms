class JWTManagerService
  class << self
    def decode(jwt:)
      payload, _header = JWT.decode(jwt, jwt_hmac_secret, true, algorithm: JWT_ALGORITHM)

      DecodeResult.new(payload:, error_message: nil)
    rescue JWT::ExpiredSignature then DecodeResult.new(payload: nil, error_message: JWT_EXPIRED_ERROR)
    rescue JWT::VerificationError then DecodeResult.new(payload: nil, error_message: JWT_VERIFICATION_ERROR)
    rescue JWT::DecodeError then DecodeResult.new(payload: nil, error_message: JWT_DECODE_ERROR)
    end

    def encode(payload:)
      EncodeResult.new(jwt: JWT.encode(payload, jwt_hmac_secret, JWT_ALGORITHM), error_message: nil)
    rescue JWT::EncodeError => e
      EncodeResult.new(jwt: nil, error_message: e.message)
    end

    private

    # TODO: Move to production and development rails credentials
    def jwt_hmac_secret = 'f1nd1ngN3m0'
  end

  DecodeResult = Data.define(:payload, :error_message)
  EncodeResult = Data.define(:jwt, :error_message)
  JWT_ALGORITHM = 'HS256'.freeze
  JWT_DECODE_ERROR = 'JWT is invalid and cannot be decoded.'.freeze
  JWT_EXPIRED_ERROR = 'JWT is expired, please trying logging in again!'.freeze
  JWT_VERIFICATION_ERROR = 'JWT cannot be verified.'.freeze
end
