# frozen_string_literal: true

# == Schema Information
#
# Table name: problems
#
# @!attribute id
#   @return []
# @!attribute body
#   @return [String]
# @!attribute resolved_at
#   @return [Time]
# @!attribute title
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute assigned_to_id
#   @return []
# @!attribute problem_type_id
#   @return []
# @!attribute resolved_by_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_problems_on_assigned_to_id   (assigned_to_id)
#  index_problems_on_body             (body)
#  index_problems_on_problem_type_id  (problem_type_id)
#  index_problems_on_resolved_at      (resolved_at)
#  index_problems_on_resolved_by_id   (resolved_by_id)
#  index_problems_on_shipment_id      (shipment_id)
#  index_problems_on_title            (title)
#
# Foreign Keys
#
#  fk_rails_...  (assigned_to_id => users.id)
#  fk_rails_...  (problem_type_id => problem_types.id)
#  fk_rails_...  (resolved_by_id => users.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class Problem < ApplicationRecord
  belongs_to :assigned_to, class_name: 'User'
  belongs_to :problem_type
  belongs_to :resolved_by, class_name: 'User', optional: true
  belongs_to :shipment

  has_one :broker, through: :shipment

  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999999')")
  end

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(id: unresolved) }

  def resolved?
    !resolved_at.blank?
  end
end
