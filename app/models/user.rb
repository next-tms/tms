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
    sales_rep_for_broker_customers.include? broker_customer
  end

  def sales_rep_for_broker_customers
    if has_role? 'sales_rep_for_all_broker_customers'
      broker.broker_customers
    else
      broker_customers
    end
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
