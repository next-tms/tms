class StripeAccount < ApplicationRecord
  encrypts :encrypted_account_id

  def connected?
    encrypted_account_id.present?
  end
end
