module Companyable
  extend ActiveSupport::Concern

  included { has_many :contacts, as: :companyable, dependent: :destroy }

  def carrier?
    is_a?(Carrier)
  end

  def companyable_sgid
    to_sgid_param
  end

  def customer?
    is_a?(BrokerCustomer)
  end
end
