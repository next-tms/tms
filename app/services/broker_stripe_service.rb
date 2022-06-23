# Provides access to broker's Stripe API
class BrokerStripeService
  class << self
    def client(stripe_account:)
      Stripe::StripeClient.new({ api_key: stripe_account.encrypted_api_key })
    end
  end
end
