# frozen_string_literal: true

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
class Problem < ApplicationRecord
  belongs_to :assigned_to, class_name: 'User'
  # belongs_to :problem_type
  belongs_to :resolvable, polymorphic: true
  belongs_to :resolved_by, class_name: 'User', optional: true

  has_one :broker, through: :assigned_to
  has_one :role, through: :problem_type

  validates :problematic_rule_code, presence: true

  validate :validate_problematic_rule_code

  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999999')")
  end

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(id: unresolved) }

  def resolved?
    !resolved_at.blank?
  end

  private

  def validate_problematic_rule_code
    return unless new_record? &&
                  problematic_rule_code.present? &&
                  !resolvable.class.problematic_rule_codes.include?(problematic_rule_code.to_sym)

    errors.add(
      :problematic_rule_code,
      "must be one of #{resolvable.class.problematic_rule_codes.join(', ')}, got #{problematic_rule_code}"
    )
  end
end
