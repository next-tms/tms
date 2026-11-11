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
