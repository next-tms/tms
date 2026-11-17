module APIRateLimiting
  extend ActiveSupport::Concern

  included do
    rate_limit by: -> { api_key.token_digest },
               if: :api_key,
               name: 'api_key',
               to: API_KEY_LIMIT,
               with: :render_rate_limited,
               within: RATE_LIMIT_WINDOW
    rate_limit by: -> { current_user.id },
               if: -> { current_user },
               name: 'user',
               to: USER_LIMIT,
               unless: :api_key,
               with: :render_rate_limited,
               within: RATE_LIMIT_WINDOW
  end

  API_KEY_LIMIT = 300
  RATE_LIMIT_WINDOW = 1.minute
  USER_LIMIT = 600

  private

  def render_rate_limited
    response.headers['Retry-After'] = RATE_LIMIT_WINDOW.to_i.to_s

    render(:rate_limited, status: :too_many_requests)
  end
end
