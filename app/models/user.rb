# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
# @!attribute id
#   @return [Integer]
# @!attribute confirmation_sent_at
#   @return [Time]
# @!attribute confirmation_token
#   @return [String]
# @!attribute confirmed_at
#   @return [Time]
# @!attribute current_sign_in_at
#   @return [Time]
# @!attribute current_sign_in_ip
#   @return [String]
# @!attribute email
#   @return [String]
# @!attribute encrypted_password
#   @return [String]
# @!attribute failed_attempts
#   @return [Integer]
# @!attribute first_name
#   @return [String]
# @!attribute invitation_accepted_at
#   @return [Time]
# @!attribute invitation_created_at
#   @return [Time]
# @!attribute invitation_limit
#   @return [Integer]
# @!attribute invitation_sent_at
#   @return [Time]
# @!attribute invitation_token
#   @return [String]
# @!attribute invitations_count
#   @return [Integer]
# @!attribute last_name
#   @return [String]
# @!attribute last_sign_in_at
#   @return [Time]
# @!attribute last_sign_in_ip
#   @return [String]
# @!attribute locked_at
#   @return [Time]
# @!attribute phone
#   @return [String]
# @!attribute receive_email_notifications
#   @return [Boolean]
# @!attribute receive_notifications_from_self
#   @return [Boolean]
# @!attribute receive_sms_notifications
#   @return [Boolean]
# @!attribute remember_created_at
#   @return [Time]
# @!attribute reset_password_sent_at
#   @return [Time]
# @!attribute reset_password_token
#   @return [String]
# @!attribute sign_in_count
#   @return [Integer]
# @!attribute time_zone
#   @return [String]
# @!attribute unconfirmed_email
#   @return [String]
# @!attribute unlock_token
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute contact_id
#   @return []
# @!attribute invited_by_id
#   @return []
#
# Indexes
#
#  index_users_on_broker_customer_id    (broker_customer_id)
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_contact_id            (contact_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (invited_by_id => users.id)
#
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
  accepts_nested_attributes_for :user_roles, allow_destroy: true, reject_if: :all_blank

  has_many :roles, through: :user_roles

  has_many :broker_customer_sales_reps
  has_many :broker_customers, through: :broker_customer_sales_reps

  has_many :commissions

  serialize :time_zone
  validates_presence_of :time_zone

  validates_presence_of :first_name
  validates_presence_of :last_name

  scope :broker, -> { where(broker_customer: nil) }
  scope :customer, -> { where.not(broker_customer: nil) }

  def active_for_authentication?
    super && !deactivated
  end

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
    contact = Contact.new if :new_record? && contact.blank?

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
