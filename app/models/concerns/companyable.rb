module Companyable
  extend ActiveSupport::Concern

  included do
    has_many :contacts, as: :companyable, dependent: :destroy
  end

  def carrier?
    is_a?(BrokerCarrier)
  end

  def companyable_sgid
    to_sgid_param
  end

  def customer?
    is_a?(BrokerCustomer)
  end
end
