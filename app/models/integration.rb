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
class Integration < ApplicationRecord
  class << self
    def connected?(kind) = where(kind:).any?(&:connected?)
  end

  SERVICES = { quickbooks: 'Accounting::QuickBooks::Service', wave: 'Accounting::Wave::Service' }.freeze

  enum :kind, SERVICES.keys.index_with(&:to_s)

  encrypts :credentials

  has_many :integration_mappings, dependent: :destroy

  delegate :connected?, :validate_credentials, to: :service

  validate :validate_accounting_count
  validate :validate_credentials

  validates :name, presence: true, uniqueness: { scope: :kind }

  def service = @service ||= SERVICES.fetch(kind.to_sym).constantize.new(self)

  private

  def validate_accounting_count
    return unless Accounting::KINDS.include?(kind.to_sym) && connected?
    return unless Integration.where(kind: Accounting::KINDS).where.not(id:).any?(&:connected?)

    errors.add(:base, 'another accounting integration is already connected')
  end
end
