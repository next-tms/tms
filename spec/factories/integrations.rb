# == Schema Information
#
# Table name: integrations
#
# @!attribute id
#   @return []
# @!attribute credentials
#   @return [Hash]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_integrations_on_kind_and_name  (kind,name) UNIQUE
#
# @!attribute id
#   @return []
# @!attribute credentials
#   @return [Hash]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_integrations_on_kind_and_name  (kind,name) UNIQUE
#
FactoryBot.define do
  factory(:integration) do
    credentials do
      {
        access_token: Faker::Internet.username,
        realm_id: Faker::Number.number(digits: 16).to_s,
        refresh_token: Faker::Internet.username
      }
    end

    kind { :quickbooks }
    name { Faker::Company.name }

    trait(:wave) do
      credentials do
        {
          access_token: Faker::Internet.username,
          business_id: Faker::Alphanumeric.alphanumeric(number: 36),
          refresh_token: Faker::Internet.username
        }
      end

      kind { :wave }
    end
  end
end
