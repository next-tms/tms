# == Schema Information
#
# Table name: api_keys
#
# @!attribute id
#   @return []
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
# @!attribute rolled_from_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_api_keys_on_rolled_from_id  (rolled_from_id)
#  index_api_keys_on_token_digest    (token_digest) UNIQUE
#  index_api_keys_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (rolled_from_id => api_keys.id)
#  fk_rails_...  (user_id => users.id)
#
# @!attribute id
#   @return []
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
# @!attribute rolled_from_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_api_keys_on_rolled_from_id  (rolled_from_id)
#  index_api_keys_on_token_digest    (token_digest) UNIQUE
#  index_api_keys_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (rolled_from_id => api_keys.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :api_key do
    name { "#{Faker::App.name} #{SecureRandom.hex(4)}" }
    ttl { APIKey::MAX_TTL }
    user factory: :customer_user

    trait :carrier do
      user factory: :carrier_user
    end
  end
end
