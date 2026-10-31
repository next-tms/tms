class MoveBrokerToSettings < ActiveRecord::Migration[8.1]
  class Broker < ApplicationRecord; end
  class Setting < ApplicationRecord; end
  class Suppression < ApplicationRecord; end
  class Suppressor < ApplicationRecord; end

  COLUMNS = [
    'automatically_authorize_receivables',
    'automatically_update_shipment_tracking_based_on_carrier_apis',
    'customer_service_email',
    'default_bol_notes',
    'first_load_id',
    'ignore_broker_carrier_bol_requires_tracking_number',
    'name',
    'phone',
    'requires_charges_confirmed_on_receivables',
    'robot_email',
    'theme_primary_color',
    'theme_sidebar_background_color',
    'theme_sidebar_text_color',
    'time_zone_name'
  ].freeze
  INSTIGATED_MODELS = [Suppression, Suppressor].freeze

  def up
    raise "Expected at most one broker, found #{Broker.count}" if Broker.count > 1

    broker = Broker.first
    return if broker.blank?

    say('populate(:settings)')

    values = COLUMNS.index_with { |column| serialize(broker[column]) }
    values['mailing_address'] = serialize(broker.address_id)

    values.compact.each do |key, value|
      setting = Setting.find_or_initialize_by(key:)
      next if setting.value == value

      say("Replaced setting #{key}=#{setting.value.inspect} with broker #{value.inspect}", true) if setting.value.present?
      setting.update!(value:)
    end

    instigator = Setting.find_by(key: 'requires_charges_confirmed_on_receivables')
    return if instigator.blank?

    say('populate(:suppressors, :instigator)')

    INSTIGATED_MODELS.each do |model|
      model.where(instigator_type: 'Broker').update_all(instigator_id: instigator.id, instigator_type: 'Setting')
    end
  end

  def down
    broker = Broker.first
    return if broker.blank?

    say('populate(:suppressors, :instigator)')

    INSTIGATED_MODELS.each do |model|
      model.where(instigator_type: 'Setting').update_all(instigator_id: broker.id, instigator_type: 'Broker')
    end
  end

  private

  def serialize(value)
    case value
    when nil then nil
    when true, false then "boolean:#{value}"
    else value.to_s
    end
  end
end
