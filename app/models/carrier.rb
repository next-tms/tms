class Carrier < ApplicationRecord
  class << self
    def companyable_order = where(id: BrokerCarrier.select(:carrier_id)).or(where(id: User.carrier.select(:companyable_id))).order(:name)

    def terminals_in(city:, state:)
      region_iso31662s = Transponder::ORM::Region
                         .all
                         .select { |region| [region.abbreviation, region.name].any? { |value| value.casecmp?(state.to_s) } }
                         .map(&:iso31662)

      local_terminals_in(city:, region_iso31662s:) + transponder_terminals_in(city:, region_iso31662s:)
    end

    private

    def local_terminals_in(city:, region_iso31662s:)
      Terminal
        .includes(:address)
        .where(carrier: all, addresses: { region_iso31662: region_iso31662s })
        .where(Address.arel_table[:city].matches(city))
        .to_a
    end

    def transponder_terminals_in(city:, region_iso31662s:)
      all
        .flat_map { |carrier| carrier.transponder_terminals.to_a }
        .select { |terminal| terminal.address&.located_in?(city:, region_iso31662s:) }
    end
  end

  include Companyable

  has_many :broker_carriers, dependent: :restrict_with_error
  has_many :terminals, dependent: :destroy
  has_many :users, as: :companyable, dependent: :restrict_with_error

  has_many :api_keys, through: :users
  has_many :payment_transactions, through: :broker_carriers
  has_many :payments, through: :broker_carriers
  has_many :shipments, through: :broker_carriers

  belongs_to :broker_billing_address, class_name: 'Address', optional: true
  belongs_to :check_mailing_address, class_name: 'Address', optional: true

  belongs_to_transponder :transponder_carrier, class_name: 'Carrier', foreign_key: :transponder_id, optional: true

  accepts_nested_attributes_for :check_mailing_address

  delegate :bol_requires_tracking_number?,
           :create_pickup_implemented?,
           :find_rates_implemented?,
           :find_rates_with_declared_value?,
           :headquarters,
           :pickup_number_is_tracking_number?,
           :rates_with_excessive_length_fees?,
           :us_dot_number,
           :website_url,
           to: :transponder_carrier,
           allow_nil: true
  delegate :check_mailing_addresses,
           :contacts,
           :lanes,
           :matching_lanes,
           :serve?,
           :terminals,
           :territories,
           to: :transponder_carrier,
           prefix: :transponder,
           allow_nil: true

  scope :with_api, -> { where(transponder_id: Transponder::ORM::Carrier.all.select(&:api?).map(&:id)) }

  validates :name, uniqueness: true
  validates :mc_number, :scac, :transponder_id, uniqueness: { allow_nil: true }

  def required_credential_types = transponder_carrier&.required_credential_types || []
  def valid_tracking_number?(tracking_number) = transponder_carrier.nil? || transponder_carrier.valid_tracking_number?(tracking_number)
end
