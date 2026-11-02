# == Schema Information
#
# Table name: api_keys
#
# @!attribute id
#   @return []
# @!attribute authorizable_type
#   @return [String]
# @!attribute expires_at
#   @return [Time]
# @!attribute last_used_at
#   @return [Time]
# @!attribute name
#   @return [String]
# @!attribute token
#   @return [String]
# @!attribute token_digest
#   @return [String]
# @!attribute token_suffix
#   @return [String]
# @!attribute ttl
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute authorizable_id
#   @return []
# @!attribute rolled_from_id
#   @return []
#
# Indexes
#
#  index_api_keys_on_authorizable    (authorizable_type,authorizable_id)
#  index_api_keys_on_rolled_from_id  (rolled_from_id)
#  index_api_keys_on_token_digest    (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (rolled_from_id => api_keys.id)
#
FactoryBot.define do
  factory :api_key do
    authorizable factory: :customer_user
    name { "#{Faker::App.name} #{SecureRandom.hex(4)}" }
    ttl { APIKey::MAX_TTL }

    trait :broker_carrier do
      authorizable factory: :broker_carrier
      ttl { nil }
    end
  end
end
