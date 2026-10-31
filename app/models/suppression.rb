# == Schema Information
#
# Table name: suppressions
#
# @!attribute id
#   @return []
# @!attribute ignored_at
#   @return [Time]
# @!attribute instigator_type
#   @return [String]
# @!attribute problematic_type
#   @return [String]
# @!attribute suppressible_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute ignored_by_id
#   @return []
# @!attribute instigator_id
#   @return []
# @!attribute problem_id
#   @return []
# @!attribute problematic_id
#   @return []
# @!attribute suppressor_id
#   @return []
#
# Indexes
#
#  index_suppressions_on_ignored_by_id      (ignored_by_id)
#  index_suppressions_on_instigator         (instigator_type,instigator_id)
#  index_suppressions_on_problem_id         (problem_id)
#  index_suppressions_on_problematic        (problematic_type,problematic_id)
#  index_suppressions_on_suppressible_type  (suppressible_type)
#  index_suppressions_on_suppressor_id      (suppressor_id)
#
# Foreign Keys
#
#  fk_rails_...  (ignored_by_id => users.id)
#  fk_rails_...  (problem_id => problems.id)
#  fk_rails_...  (suppressor_id => suppressors.id)
#
class Suppression < ApplicationRecord
  before_validation :set_ignored_at
  before_validation :set_suppressible_type

  belongs_to :ignored_by, class_name: 'User', optional: true
  belongs_to :instigator, polymorphic: true
  belongs_to :problem, counter_cache: true
  belongs_to :problematic, polymorphic: true
  belongs_to :suppressor

  delegate :describe, to: :suppressor

  validates :suppressible_type, presence: true

  private

  def set_ignored_at
    return unless will_save_change_to_ignored_by_id?

    self.ignored_at = ignored_by.present? ? Time.current : nil
  end

  def set_suppressible_type
    return if suppressor.blank?

    self.suppressible_type = suppressor.suppressible_type
  end
end
