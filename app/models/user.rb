# frozen_string_literal: true

class User < ApplicationRecord
  scope :customers, -> { where.not(broker_customer: nil) }
  scope :brokers, -> { where.not(id: customers) }

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :timeoutable

  belongs_to :broker, required: true
  belongs_to :customer, required: false
  belongs_to :broker_customer, required: false

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :broker_customer_sales_reps
  has_many :broker_customers, through: :broker_customer_sales_reps

  serialize :time_zone
  validates_presence_of :time_zone

  validates_presence_of :first_name
  validates_presence_of :last_name

  def broker_customers
    if has_role?('sales_rep_for_all_broker_customers')
      broker.broker_customers
    else
      super
    end
  end

  def sales_rep_for?(broker_customer)
    return nil unless broker_customer.blank?
    broker_customers.include? broker_customer
  end

  def sales_rep_for_broker_customers
    BrokerCustomer.where(
      id: BrokerCustomerSalesRep.where(
        user: self
      ).pluck(:broker_customer_id)
    )
  end

  def sales_rep_earnings(from, to)
    shipments = Shipment.active.where(
      broker_customer: broker_customers
    ).where(
      'picked_up_at >= ?', from
    ).where(
      'picked_up_at <= ?', to
    )

    return Money.new(0) if shipments.blank?

    earnings = Money.new(0)

    shipments.find_each do |shipment|
      broker_customer_sales_rep = BrokerCustomerSalesRep.where(
        user: self,
        broker_customer: shipment.broker_customer
      )&.first

      next if broker_customer_sales_rep.blank?
      unless !broker_customer_sales_rep.commission_percent.blank?
        earnings += shipment.profit * (broker_customer_sales_rep.commission_percent / 100)
      end
      unless broker_customer_sales_rep.commission_flat.blank?
        earnings += shipment.profit + broker_customer_sales_rep.commission_flat
      end
    end

    earnings
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

    broker_customer_ids = sales_rep_for_broker_customers&.pluck(:id)
    return Shipment.where(broker_customer_id: broker_customer_ids) unless broker_customer_ids.blank?

    Shipment.none
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
      url: 'https://liftoff.rocks/Liftoff%20TMS.vcf'
    )
  end
end
