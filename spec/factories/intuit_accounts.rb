# == Schema Information
#
# Table name: intuit_accounts
#
# @!attribute id
#   @return []
# @!attribute encrypted_oauth2_access_token
#   @return [String]
# @!attribute encrypted_oauth2_refresh_token
#   @return [String]
# @!attribute oauth2_access_token_expires_at
#   @return [Time]
# @!attribute oauth2_refresh_token_expires_at
#   @return [Time]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_id
#   @return []
# @!attribute realm_id
#   @return [String]
#
# Indexes
#
#  index_intuit_accounts_on_broker_id  (broker_id)
#
FactoryBot.define do
  factory :intuit_account do
    broker { create(:broker) }
  end
end
