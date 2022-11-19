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
  include HasProblematicRule

  after_save :update_suppressions

  alias_attribute :problematic, :resolvable

  belongs_to :assigned_to, class_name: 'User'
  # belongs_to :problem_type
  belongs_to :resolvable, polymorphic: true # TODO: Rename to problematic
  belongs_to :resolved_by, class_name: 'User', optional: true

  has_many :suppressions, dependent: :destroy

  has_one :broker, through: :assigned_to
  has_one :role, through: :problem_type

  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999999')")
  end

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(id: unresolved) }
  scope :suppressive, -> { unresolved.where.not(suppresions: []) }

  # @note For HasProblematicRule
  def problematic_type
    resolvable.class.name
  end

  def resolved?
    resolved_at.present?
  end

  def suppressive?
    return true unless resolved? || suppressions.empty?
  end

  def unresolved?
    !resolved?
  end

  private

  def update_suppressions
    suppressions.destroy_all and return if resolved?

    return unless problematic_rule.present?

    suppressors = problematic_rule.with(problematic).suppressors
    return unless suppressors.any?

    suppressions.where.not(suppressor: suppressors).destroy_all

    suppressors.find_each do |suppressor|
      suppressions.find_or_create_by!(
        instigator: suppressor.instigator,
        problem: self,
        problematic: resolvable,
        suppressible_type: suppressor.suppressible_type,
        suppressor:
      )
    end
  end
end
