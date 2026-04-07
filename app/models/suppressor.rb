# frozen_string_literal: true

# == Schema Information
#
# Table name: suppressors
#
# @!attribute id
#   @return []
# @!attribute instigator_type
#   @return [String]
# @!attribute problematic_rule_code
#   @return [String]
# @!attribute problematic_type
#   @return [String]
# @!attribute suppressible_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute instigator_id
#   @return []
#
# Indexes
#
#  index_suppressors_on_instigator             (instigator_type,instigator_id)
#  index_suppressors_on_problematic_rule_code  (problematic_rule_code)
#  index_suppressors_on_problematic_type       (problematic_type)
#  index_suppressors_on_suppressible_type      (suppressible_type)
#
class Suppressor < ApplicationRecord
  include HasProblematicRule

  after_create :update_problematic_records_later

  belongs_to :instigator, polymorphic: true

  has_many :suppressions, dependent: :destroy

  validates :problematic_type, inclusion: { in: %w[Shipment] }, presence: true
  validates :suppressible_type, inclusion: { in: %w[Receivable] }, presence: true

  def describe
    return nil unless valid?

    instigator_name = begin
      instigator.name.presence || instigator.class.model_name.human
    rescue NameError
      instigator.class.model_name.human
    end

    <<~DESCRIBE.squish
      #{instigator_name} prevents #{suppressible_type.constantize.model_name.human.downcase}
      from being created when its #{problematic_type.constantize.model_name.human.downcase} is
      #{problematic_rule.humanized.downcase}
    DESCRIBE
  end

  private

  def update_problematic_records_later
    problematic_records = instigator.public_send(problematic_type.pluralize.underscore.to_sym)

    return unless problematic_records.any?

    ProblematicJob.perform_later(problematic_records.ids, type: problematic_type)
  end
end
