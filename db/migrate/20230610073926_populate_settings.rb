class PopulateSettings < ActiveRecord::Migration[7.0]
  def up
    broker = Broker.first
    broker_keys.each do |key|
      value = broker.public_send(key)
      next if value.blank?

      Setting.create!(key:, value:)
    end

    website = Website.first
    website_keys.each do |key|
      value = website.public_send(key)
      next if value.blank?

      Setting.create!(key: "website_#{key}", value:)
    end
  end

  def down; end

  private

  def broker_keys
    %i[
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
    ]
  end

  def website_keys
    %i[
      copyright_holder
      desc
      homepage
      logo_image_data
      sign_out_url
      slogan
    ]
  end
end
