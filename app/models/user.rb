# frozen_string_literal: true

class User < ApplicationRecord
  scope :customers, -> { where.not(broker_customer: nil) }
  scope :brokers, -> { where.not(id: customers) }

  devise :database_authenticatable, :invitable, :recoverable, :rememberable, :trackable, :validatable, :timeoutable

  before_save :update_contact

  belongs_to :broker, required: true
  belongs_to :contact
  belongs_to :customer, required: false
  belongs_to :broker_customer, required: false

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :broker_customer_sales_reps
  has_many :broker_customers, through: :broker_customer_sales_reps

  has_many :commissions, through: :broker_customer_sales_reps

  serialize :time_zone
  validates_presence_of :time_zone

  validates_presence_of :first_name
  validates_presence_of :last_name

  scope :broker, -> { where(broker_customer: nil) }
  scope :customer, -> { where.not(broker_customer: nil) }

  def full_name
    @full_name ||= "#{first_name} #{last_name}"
  end

  def label
    full_name
  end

  def broker_customers
    if has_role?('sales_rep_for_all_broker_customers')
      broker.broker_customers
    else
      super
    end
  end

  def sales_rep_for?(broker_customer)
    return false if broker_customer.blank?

    broker_customers.include?(broker_customer)
  end

  def sales_rep_for_broker_customers
    BrokerCustomer.where(
      id: BrokerCustomerSalesRep.where(
        user: self
      ).pluck(:broker_customer_id)
    )
  end

  def commissions_between(from, to)
    commissions.where(
      shipment: shipments.where(delivered_at: from..to)
    )
  end

  def has_role?(role_name)
    role_names = roles.map(&:name)
    return true if role_names.include? 'root'

    role_names << 'broker' if broker?
    role_names << 'customer' if customer?
    role_names.include? role_name
  end

  def self.with_role(role_name)
    joins(:user_roles).where(user_roles: { role: Role.find_by_name(role_name) })
  end

  def customer?
    @customer ||= broker_customer ? true : false
  end

  def broker?
    @broker ||= !customer?
  end

  def shipments
    return broker_customer.shipments if customer?

    if !sales_rep_only? && (has_role?('sales_rep_for_all_broker_customers') || has_role?('dispatch'))
      return broker.shipments
    end

    broker_customer_ids = sales_rep_for_broker_customers&.pluck(:id)

    return Shipment.none if broker_customer_ids.blank?

    Shipment.where(broker_customer_id: broker_customer_ids) unless broker_customer_ids.blank?
  end

  def sales_rep_only?
    roles.map(&:name) == ['sales_rep']
  end

  def enable_notifications
    UserTexter.switch_on(self).deliver

    client = Twilio::REST::Client.new
    client.api.account.messages.create(
      from: '+14243616317',
      to: phone,
      url: 'https://tms.next-tms.com/Next%%20TMS.vcf'
    )
  end

  private

  def update_contact
    contact = Contact.new if :new_record?

    contact.assign_attributes(
      broker_customer: broker_customer,
      broker: broker,
      email: email,
      first_name: first_name,
      last_name: last_name
    )

    contact.save
    self.contact = contact
  end
end
