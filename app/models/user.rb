class User < ApplicationRecord
  class << self
    def notification_types
      [
        'document:broker_bol',
        'document:broker_dispatch_sheet',
        'document:broker_quote',
        'document:carrier_bol',
        'document:carrier_pod',
        'pickup:pickup_service_dispatched',
        'shipment:booked_at',
        'shipment:canceled_at',
        'shipment:delivered_at',
        'shipment:delivery_appointment_at',
        'shipment:delivery_appointment_on',
        'shipment:delivery_eta_on',
        'shipment:departed_origin_terminal_at',
        'shipment:dispatcher_id',
        'shipment:new_shipment',
        'shipment:out_for_delivery_at',
        'shipment:picked_up_at'
      ]
    end

    def with_any_role(*roles)
      joins(:contact).where(contact: Contact.with_any_role(*roles))
    end

    def with_role(role)
      joins(:contact).where(contact: Contact.with_role(role))
    end
  end

  include HasCompanyable

  after_save :reassign_problems
  after_save :reassign_shipments
  after_save :send_invitation
  after_save :update_contact

  before_validation :build_contact, if: -> { contact.blank? && email.present? }
  before_validation :set_time_zone_name, if: -> { new_record? && time_zone_name.blank? }

  belongs_to :contact

  delegate :add_role, :any_role?, :dispatcher?, :role, :role?, :roles, to: :contact

  devise :database_authenticatable, :invitable, :pwned_password, :recoverable, :rememberable, :timeoutable, :trackable, :validatable

  before_invitation_created :set_time_zone_name, if: -> { new_record? && time_zone_name.blank? }

  has_many :api_keys, dependent: :destroy
  has_many :broker_customer_sales_reps, dependent: :destroy
  has_many :commissions, dependent: :restrict_with_error
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: 'Noticed::Notification'
  has_many :problems, dependent: :nullify, foreign_key: :assigned_to_id, inverse_of: :assigned_to
  has_many :shipments_as_dispatcher, class_name: 'Shipment', dependent: :nullify, foreign_key: :dispatcher_id, inverse_of: :dispatcher

  has_many :broker_customers, through: :broker_customer_sales_reps

  has_many :subscriptions, through: :contact

  has_many :discussions, through: :subscriptions, source: :record, source_type: 'Discussion'
  has_many :discussion_topics, through: :subscriptions, source: :record, source_type: 'DiscussionTopic'

  phony_normalize :phone, default_country_code: 'US'

  scope :active, -> { where.not(deactivated: true) }
  scope :dispatchers, -> { broker.with_role(:dispatch) }

  validate :validate_time_zone_name, if: -> { time_zone_name.present? && time_zone_name_changed? }
  validates :locale, allow_nil: true, inclusion: { in: -> { I18n.available_locales.map(&:to_s) } }
  validates :time_zone_name, presence: true

  accepts_nested_attributes_for :contact, allow_destroy: true, reject_if: :all_blank

  def active_for_authentication?
    super && !deactivated
  end

  def build_contact(attributes = {})
    new_contact = Contact.find_or_initialize_by(companyable:, email: email.downcase)
    return if new_contact.persisted?

    new_contact.assign_attributes(attributes.to_h.merge(companyable:, first_name:, last_name:))

    self.contact = new_contact
  end

  def country_code
    address = broker? ? Setting.mailing_address : companyable.try(:office_address)

    address&.country_alpha2.presence || 'US'
  end

  def full_name
    @full_name ||= "#{first_name} #{last_name}"
  end

  def label
    full_name
  end

  def broker_customers
    return BrokerCustomer.none unless broker?

    return BrokerCustomer.all if any_role?(:dispatch, :sales_rep_for_all_broker_customers)

    super
  end

  def dispatcher_only?
    roles == %i[dispatch]
  end

  def dispatcher_for?(shipment)
    return false if shipment.blank?

    return true if shipment.dispatcher == self

    role?(:dispatch)
    # shipments_as_dispatcher.include?(shipment)
  end

  def sales_rep_for?(broker_customer)
    return false unless broker?

    broker_customers.include?(broker_customer)
  end

  def sales_rep_for_broker_customers
    BrokerCustomer.where(id: BrokerCustomerSalesRep.where(user: self).select(:broker_customer_id))
  end

  def commissions_between(from, to)
    commissions.where(shipment: shipments.where(delivered_at: from..to))
  end

  def coworkers
    return unless broker?

    return User.broker if role?(:root)

    scope = roles - [Role.find_by(name: 'sales_rep')]
    User.where(id: UserRole.where(role: scope).where(user: User.broker).select(:user_id))
  end

  def shipments
    return companyable.shipments if customer?

    all_shipments = any_role?(:accounts_receivable, :dispatch, :root, :sales_rep_for_all_broker_customers)
    return Shipment.all if !sales_rep_only? && all_shipments

    broker_customer_ids = sales_rep_for_broker_customers&.ids

    return Shipment.none if broker_customer_ids.blank?

    Shipment.where(broker_customer_id: broker_customer_ids) if broker_customer_ids.present?
  end

  def sales_rep_only?
    roles == %i[sales_rep]
  end

  def type
    return :broker if broker?

    :customer if customer?
  end

  def enable_notifications
    UserTexter.switch_on(self).deliver

    client = Twilio::REST::Client.new
    client.api.account.messages.create(from: '+14243616317', to: phone, url: 'https://tms.next-tms.com/Next%%20TMS.vcf')
  end

  def time_zone
    ActiveSupport::TimeZone.new(time_zone_name)
  end

  protected

  # @note For Devise trackable
  def extract_ip_from(request)
    header = request.headers['Fly-Client-IP'].presence || request.headers['X-Forwarded-For']

    return request.remote_ip if header.blank?

    header = header.split(',')[0].strip if header.include?(',')
    header
  end

  private

  def reassign_problems
    return unless saved_change_to_deactivated && deactivated?

    problems.unresolved.find_each { |p| p.update(assigned_to: ProblemService.assign(broker, p.problem_type)) }
  end

  def reassign_shipments
    return unless saved_change_to_deactivated && deactivated?

    shipments_as_dispatcher.not_canceled.not_delivered.find_each do |shipment|
      shipment.dispatcher = nil
      shipment.assign_dispatcher
      shipment.save
    end
  end

  def send_invitation
    return if invitation_accepted? || !saved_change_to_email?

    invite!(invited_by)
  end

  def set_time_zone_name = self.time_zone_name = customer? ? companyable.office_address.time_zone.tzinfo.name : Setting.time_zone_name

  def update_contact
    %i[companyable_id companyable_type first_name last_name].each do |attribute|
      next unless public_send("saved_change_to_#{attribute}?")

      value = public_send(attribute)
      next if value.blank? && %i[first_name last_name].include?(attribute)

      contact.public_send("#{attribute}=", value)
    end

    contact.save! if contact.changed?
  end

  def validate_time_zone_name
    errors.add(:time_zone_name, :invalid) if time_zone.blank?
  end
end
