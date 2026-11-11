class Problem < ApplicationRecord
  class << self
    def by_any_role(*roles)
      records = none
      ProblematicService::Rule.by_any_role(*roles).map do |problematic_rule|
        records = records.or(where(problematic_rule_code: problematic_rule.code, resolvable_type: problematic_rule.model.name))
      end

      records
    end
  end

  include DiscussableTopic
  include HasProblematicRule

  after_save :update_suppressions

  belongs_to :assigned_to, class_name: 'User'
  belongs_to :resolvable, polymorphic: true # TODO: Rename to problematic
  belongs_to :resolved_by, class_name: 'User', optional: true

  has_many :suppressions, dependent: :destroy

  has_one :role, through: :problem_type

  ransacker(:id_text) { Arel.sql("CAST(\"#{table_name}\".\"id\" AS text)") }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(id: unresolved) }
  scope :suppressive, -> { unresolved.where(suppressions_count: (1..)) }

  def build_discussable_topic?
    true
  end

  def contact_scope
    :broker
  end

  # @note `delegate`, `has_one` both fail in `before_save` callback so it should be a method
  def discussion
    resolvable&.discussion
  end

  def discussable_topic_description
    title
  end

  def eligible_discussable_contacts
    Contact.where(id: discussion.subscriptions.active.pluck(:contact_id)).broker
  end

  def discussion_topic_translation_key
    problematic_rule_code
  end

  # @note For HasProblematicRule
  def problematic_type
    resolvable.class.name
  end

  def resolved?
    resolved_at.present?
  end

  def suppressive?
    unresolved? && suppressions.any?
  end

  def unresolved?
    !resolved?
  end

  private

  def update_suppressions
    suppressions.destroy_all && return if resolved?

    return if problematic_rule.blank?

    suppressors = problematic_rule.with(resolvable).suppressors
    return if suppressors.none?

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
