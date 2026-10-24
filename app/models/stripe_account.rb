# == Schema Information
#
# Table name: stripe_accounts
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute encrypted_account_id
#   @return [String]
#
class StripeAccount < ApplicationRecord
  encrypts :encrypted_account_id

  def connected?
    encrypted_account_id.present?
  end
end
