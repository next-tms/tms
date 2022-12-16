class JwtManagerService
  JWT_ALGORITHM = "HS256".freeze
  # JWT related error messages
  JWT_DECODE_ERROR = "JWT is invalid and cannot be decoded.".freeze
  JWT_EXPIRED_ERROR = "JWT is expired, please trying logging in again!".freeze
  JWT_VERIFICATION_ERROR = "JWT cannot be verified.".freeze

  def self.encode(payload:)
    begin
      jwt = JWT.encode(payload, jwt_hmac_secret, JWT_ALGORITHM)
    rescue EncodeError => e
      error_message = e.message
    end
    OpenStruct.new(jwt: jwt,
                   error_message: error_message)
  end

  def self.decode(jwt:)
    error_message = begin
                      decoded_token = JWT.decode(jwt,
                                                 jwt_hmac_secret,
                                                 true,
                                                 algorithm: JWT_ALGORITHM)
                      nil
                    rescue JWT::ExpiredSignature then JWT_EXPIRED_ERROR
                    rescue JWT::VerificationError then JWT_VERIFICATION_ERROR
                    rescue JWT::DecodeError then JWT_DECODE_ERROR
                    end
    OpenStruct.new(payload: decoded_token&.first, error_message: error_message)
  end

  private_class_method def self.jwt_hmac_secret
    # TODO: Move to production and development rails credentials
    "f1nd1ngN3m0"
  end
end
