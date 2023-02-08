# frozen_string_literal: true

module HasCompanyable
  extend ActiveSupport::Concern

  included do
    belongs_to :companyable, polymorphic: true

    delegate :broker, :broker?, :carrier?, :customer?, to: :companyable

    scope :broker, -> { where(companyable_type: 'Broker') }
    scope :customer, -> { where(companyable_type: 'BrokerCustomer') }
  end

  def companyable_sgid
    companyable&.to_sgid_param
  end

  def companyable_sgid=(sgid)
    self.companyable = GlobalID::Locator.locate_signed(sgid)
  end
end
