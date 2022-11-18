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
  scope :active, -> { where.not(deactivated: true) }
  scope :customers, -> { where.not(broker_customer: nil) }
  scope :brokers, -> { where.not(id: customers) }
  scope :dispatchers, -> { where(id: Role.find_by(name: 'dispatch')&.users&.collect(&:id)) }

  devise :database_authenticatable, :invitable, :pwned_password, :recoverable, :rememberable, :timeoutable, :trackable,
         :validatable

  after_save :reassign_problems
  after_save :reassign_shipments
  after_save :send_invitation

  before_validation :set_contact
  before_validation :set_time_zone_name

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
  has_many :shipments_as_dispatcher, class_name: 'Shipment', foreign_key: :dispatcher_id

  has_many :problems, foreign_key: 'assigned_to_id'

  has_many :notifications, as: :recipient

  phony_normalize :phone, default_country_code: 'US'

  validates :time_zone_name, presence: true

  scope :broker, -> { where(broker_customer: nil) }
  scope :customer, -> { where.not(broker_customer: nil) }

  def active_for_authentication?
    super && !deactivated
  end

  def country_code
    broker&.address&.country&.alpha2_code || 'US'
  end

  def full_name
    @full_name ||= "#{first_name} #{last_name}"
  end

  def label
    full_name
  end

  def broker_customers
    if has_any_roles?(%w[dispatch sales_rep_for_all_broker_customers])
      broker.broker_customers
    else
      super
    end
  end

  def dispatcher_only?
    return false if has_role?('root')

    roles.count == 1 && has_role?('dispatch')
  end

  def dispatcher_for?(shipment)
    return false if shipment.blank?

    return true if shipment.dispatcher == self

    has_role?('dispatch')
    # shipments_as_dispatcher.include?(shipment)
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

  def has_any_roles?(role_arr)
    role_arr.map(&method(:has_role?)).any?(true)
  end

  def has_role?(role_name)
    @role_names ||= roles.pluck(:name)
    return true if @role_names.include?('root')

    if customer? && role_name == 'accounts_payable' && broker_customer.primary_receivables_contact == contact
      return true
    end

    @role_names << 'broker' if broker?
    @role_names << 'customer' if customer?
    @role_names.include? role_name
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

  def dispatcher?
    roles.where(name: 'dispatch').exists?
  end

  def coworkers
    return nil unless broker?

    return broker.users.broker if has_role?('root')

    scope = roles - [Role.find_by_name('sales_rep')]

    User.where(id: UserRole.where(role: scope).where(user: broker.users.broker).pluck(:user_id))
  end

  def shipments
    return broker_customer.shipments if customer?

    all_shipments = (roles.pluck(:name) & %w[accounts_receivable dispatch root sales_rep_for_all_broker_customers]).any?
    return broker.shipments if !sales_rep_only? && all_shipments

    broker_customer_ids = sales_rep_for_broker_customers&.ids

    return Shipment.none if broker_customer_ids.blank?

    Shipment.where(broker_customer_id: broker_customer_ids) unless broker_customer_ids.blank?
  end

  def sales_rep_only?
    @role_names ||= roles.pluck(:name)
    @role_names == ['sales_rep']
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

  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name)
  end

  private

  def reassign_problems
    return unless saved_change_to_deactivated && deactivated?

    problems.unresolved.find_each { |p| p.update(assigned_to: ProblemService.assign(broker, p.problem_type)) }
  end

  def reassign_shipments
    return unless saved_change_to_deactivated && deactivated?

    Shipment.active.where(delivered_at: [nil, ''], dispatcher: self).find_each do |shipment|
      shipment.dispatcher = nil
      shipment.assign_dispatcher
      shipment.save
    end
  end

  def send_invitation
    return if invitation_accepted? || !saved_change_to_email?

    invite!(invited_by)
  end

  def set_contact
    return if email.blank?

    self.contact = broker.contacts.where(email: email.downcase)&.first
    return unless contact.blank?

    self.contact = Contact.new(
      broker_id:,
      email:,
      first_name:,
      last_name:
    )
  end

  def set_time_zone_name
    return if broker.blank?

    self.time_zone_name = broker.time_zone_name
  end

  protected

  # @note For Devise trackable
  def extract_ip_from(request)
    header = request.headers['Fly-Client-IP'].presence || request.headers['X-Forwarded-For']

    return request.remote_ip unless header.present?

    header = header.split(',')[0].strip if header.include?(',')
    header
  end
end
