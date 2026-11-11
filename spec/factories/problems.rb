# == Schema Information
#
# Table name: problems
#
# @!attribute id
#   @return []
# @!attribute body
#   @return [String]
# @!attribute problematic_rule_code
#   @return [String]
# @!attribute resolvable_type
#   @return [String]
# @!attribute resolved_at
#   @return [Time]
# @!attribute suppressions_count
#   @return [Integer]
# @!attribute title
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute assigned_to_id
#   @return []
# @!attribute resolvable_id
#   @return []
# @!attribute resolved_by_id
#   @return []
#
# Indexes
#
#  index_problems_on_assigned_to_id  (assigned_to_id)
#  index_problems_on_body            (body)
#  index_problems_on_resolvable      (resolvable_type,resolvable_id)
#  index_problems_on_resolved_at     (resolved_at)
#  index_problems_on_resolved_by_id  (resolved_by_id)
#  index_problems_on_title           (title)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_to_id => users.id)
#  fk_rails_...  (resolved_by_id => users.id)
#
# @!attribute id
#   @return []
# @!attribute body
#   @return [String]
# @!attribute problematic_rule_code
#   @return [String]
# @!attribute resolvable_type
#   @return [String]
# @!attribute resolved_at
#   @return [Time]
# @!attribute suppressions_count
#   @return [Integer]
# @!attribute title
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute assigned_to_id
#   @return []
# @!attribute resolvable_id
#   @return []
# @!attribute resolved_by_id
#   @return []
#
# Indexes
#
#  index_problems_on_assigned_to_id  (assigned_to_id)
#  index_problems_on_body            (body)
#  index_problems_on_resolvable      (resolvable_type,resolvable_id)
#  index_problems_on_resolved_at     (resolved_at)
#  index_problems_on_resolved_by_id  (resolved_by_id)
#  index_problems_on_title           (title)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_to_id => users.id)
#  fk_rails_...  (resolved_by_id => users.id)
#
FactoryBot.define do
  factory :problem do
    association :assigned_to, factory: :user
    association :resolvable, factory: :shipment

    body { Faker::Lorem.sentences(number: rand(10)).join(' ') }
    problematic_rule_code { Shipment.problematic_rule_codes.sample }
    title { Faker::Lorem.sentences(number: 1).first }

    after(:build) { |record| record.assigned_to = record.resolvable.dispatcher }
  end
end
