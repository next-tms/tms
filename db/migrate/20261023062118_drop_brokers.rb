class DropBrokers < ActiveRecord::Migration[8.1]
  class Broker < ApplicationRecord; end
  class Setting < ApplicationRecord; end

  COLUMNS = %w[
    automatically_authorize_receivables
    automatically_update_shipment_tracking_based_on_carrier_apis
    customer_service_email
    default_bol_notes
    first_load_id
    ignore_broker_carrier_bol_requires_tracking_number
    name
    phone
    requires_charges_confirmed_on_receivables
    robot_email
    theme_primary_color
    theme_sidebar_background_color
    theme_sidebar_text_color
    time_zone_name
  ].freeze

  def up = drop_table(:brokers)

  def down
    create_table(:brokers, id: :serial) do |t|
      t.references(:address, foreign_key: true)
      t.boolean(:automatically_authorize_receivables, default: false)
      t.boolean(:automatically_update_shipment_tracking_based_on_carrier_apis, default: true)
      t.string(:customer_service_email)
      t.text(:default_bol_notes)
      t.integer(:first_load_id)
      t.boolean(:ignore_broker_carrier_bol_requires_tracking_number, default: false)
      t.string(:name)
      t.string(:phone)
      t.boolean(:requires_charges_confirmed_on_receivables, default: false)
      t.string(:robot_email)
      t.string(:theme_primary_color, default: '#0d6efd')
      t.string(:theme_sidebar_background_color, default: '#E2F8FF')
      t.string(:theme_sidebar_text_color, default: 'rgba(0, 0, 0, 0.95)')
      t.string(:time_zone_name, null: false)
      t.uuid(:uuid, default: -> { 'gen_random_uuid()' }, null: false)
      t.timestamps(default: -> { 'CURRENT_TIMESTAMP' })
    end

    values = Setting.where(key: COLUMNS).to_h { |setting| [ setting.key, deserialize(setting.value) ] }
    return if values['time_zone_name'].blank?

    say('populate(:brokers)')

    Broker.reset_column_information
    Broker.create!(address_id: Setting.find_by(key: 'mailing_address')&.value, **values)
  end

  private

  def deserialize(value)
    case value
    when 'boolean:true' then true
    when 'boolean:false' then false
    else value
    end
  end
end
