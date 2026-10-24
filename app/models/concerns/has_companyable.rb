module HasCompanyable
  extend ActiveSupport::Concern

  included do
    belongs_to :companyable, optional: true, polymorphic: true

    normalizes :companyable_type, with: ->(companyable_type) { companyable_type.presence }

    scope :broker, -> { where(companyable: nil) }
    scope :customer, -> { where(companyable_type: 'BrokerCustomer') }

    validates :companyable, presence: true, if: :companyable_type?
  end

  def broker? = companyable_id.nil? && companyable_type.nil?

  def carrier? = companyable.is_a?(BrokerCarrier)

  def companyable_sgid
    companyable&.to_sgid_param
  end

  def companyable_sgid=(sgid)
    self.companyable = GlobalID::Locator.locate_signed(sgid)
  end

  def customer? = companyable.is_a?(BrokerCustomer)
end
