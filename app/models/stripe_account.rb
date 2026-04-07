# == Schema Information
#
# Table name: stripe_accounts
#
# @!attribute id
#   @return []
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_id
#   @return []
#
# Indexes
#
#  index_stripe_accounts_on_broker_id  (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#
class StripeAccount < ApplicationRecord
  belongs_to :broker

  encrypts :encrypted_account_id

  def connected?
    encrypted_account_id.present?
  end
end
