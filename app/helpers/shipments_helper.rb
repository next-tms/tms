module ShipmentsHelper
  TABLE_DATA = {
    id: {
      display_name: 'Load',
      column_name: :load_id,
      link: true,
      path: :broker_shipment_path
    },
    broker_carrier: {
      display_name: 'Carrier',
      column_name: :broker_carrier_carrier_name,
      partial: 'broker/shipments/show_many_td_broker_carrier'
    },
    broker_customer: {
      display_name: 'Customer',
      column_name: :broker_customer_customer_name,
      partial: 'broker/shipments/show_many_td_broker_customer'
    },
    created_at: {
      display_name: 'Entered',
      column_name: :created_at,
      timezone_column: 'shipper_address',
      date_format: :pretty_date
    },
    delivered_at: {
      display_name: 'Delivered',
      column_name: :delivered_at,
      timezone_column: 'receiver_address',
      date_format: :short_date
    },
    delivery_appointment_at: {
      display_name: 'Apt',
      column_name: :delivery_appointment_at,
      fallback_column: :delivery_appointment_on,
      timezone_column: 'receiver_address',
      date_format: :short_date
    },
    pickup_driver_assigned_at: {
      display_name: 'Asgn',
      column_name: :pickup_driver_assigned_at,
      partial: 'broker/shipments/show_many_td_pickup_driver_assigned_at'
    },
    pickup_eta_at: {
      display_name: 'ETA',
      column_name: :pickup_eta_at
    },
    picked_up_at: {
      display_name: 'Pickup',
      column_name: :picked_up_at,
      timezone_column: 'shipper_address',
      date_format: :short_date
    },
    pickup_hours_end_at: {
      display_name: 'Closing',
      column_name: :pickup_hours_end_at
    },
    pickup_on: {
      display_name: 'Pickup By',
      column_name: :pickup_on,
      timezone_column: 'shipper_address',
      date_format: :short_date
    },
    pickup_confirmation: {
      display_name: 'Ref',
      column_name: :pickup_confirmation,
      partial: 'broker/shipments/show_many_td_pickup_confirmation'
    },
    pro: {
      display_name: 'Pro',
      column_name: :pro
    },
    promised_delivery_by: {
      display_name: 'Promised',
      column_name: :promised_delivery_by,
      timezone_column: 'receiver_address',
      date_format: :short_date
    },
    receiver: {
      display_name: 'Consignee',
      column_name: :receiver_name,
      association_name: :receiver_address,
      address: true
    },
    shipper: {
      display_name: 'Shipper',
      column_name: :shipper_name,
      association_name: :shipper_address,
      address: true
    },
    shipper_contact_name: {
      display_name: 'Contact',
      column_name: :shipper_contact_name
    },
    status: {
      display_name: 'Status',
      column_name: :status
    },
    size: {
      display_name: 'Size',
      column_name: :size,
      partial: 'broker/shipments/show_many_td_size'
    },
    total_cost: {
      display_name: 'Cost',
      column_name: :total_cost,
      money: true
    },
    total_charges: {
      display_name: 'Charge',
      column_name: :total_charges,
      money: true
    }
  }

  def shipment_table_row_class(shipment)
    if action_name == 'pending_pickup' && !shipment.pickup_on.blank?
      current_shipper_time = DateTime.current.in_time_zone(shipment.shipper_address.time_zone.name).to_date

      if current_shipper_time > shipment.pickup_on
        'table-danger'
      elsif current_shipper_time < shipment.pickup_on
        'table-info'
      end
    elsif shipment.pending_departure?
      'table-danger'
    elsif shipment.late? || !shipment.canceled_at.blank? || shipment.dispatch_incomplete? || (!shipment.picked_up_at.blank? && shipment.missing_delivery_eta_on?)
      'table-warning'
    end
  end

=begin
  # TODO: Remove After Regression Testing
  def shipment_show_many_table(shipments:, td_names:)
    return nil if shipments.blank?

    td_names_map = [
      ['broker_carrier', 'Carrier', :broker_carrier_carrier_name],
      ['broker_customer', 'Customer', :broker_customer_customer_name],
      ['created_at', 'Entered', :created_at],
      ['delivered_at', 'Delivered', :delivered_at],
      ['delivery_appointment_at', 'Apt', :delivery_appointment_at],
      ['id', 'Load', :load_id],
      ['pickup_driver_assigned_at', 'Asgn', :pickup_driver_assigned_at],
      ['pickup_eta_at', 'ETA', :pickup_eta_at],
      ['picked_up_at', 'Pickup', :picked_up_at],
      ['pickup_hours_end_at', 'Closing', :pickup_hours_end_at],
      ['pickup_on', 'Pickup By', :pickup_on],
      ['pickup_confirmation', 'Ref', :pickup_confirmation],
      ['pro', 'Pro', :pro],
      ['promised_delivery_by', 'Promised', :promised_delivery_by],
      ['receiver', 'Consignee', :receiver_name],
      ['shipper', 'Shipper', :shipper_name],
      ['shipper_contact_name', 'Contact', :shipper_contact_name],
      ['size', 'Size', :items_count],
      ['status', 'Status', nil],
      ['total_cost', 'Cost', :total_cost_cents],
      ['total_charges', 'Charge', :total_charges_cents]
    ]

    str = '<div class="table-responsive">'
    str << '<table class="table table-condensed table-borderless table-striped table-hover">'
    str << '<thead>'
    str << '<tr>'

    td_names.each do |td_name|
      td_names_map.each do |td_names_map_line|
        next if td_names_map_line[0] == 'broker_carrier' && controller.controller_name == 'broker_carriers'
        next if td_names_map_line[0] == 'broker_customer' && controller.controller_name == 'broker_customers'

        if td_names_map_line[2].blank? || @q.blank?
          str << "<th class=\"text-nowrap\">#{td_names_map_line[1]}</th>" if td_names_map_line[0] == td_name
        elsif td_names_map_line[0] == td_name
          str << "<th class=\"text-nowrap\">#{sort_link @q, td_names_map_line[2], td_names_map_line[1]}</th>"
        end
      end
    end

    str << '</tr>'
    str << '</thead>'
    str << '<tbody>'

    shipments.each do |shipment|
      if action_name == 'pending_pickup' && !shipment.pickup_on.blank?
        if DateTime.current.in_time_zone(shipment.shipper_address.time_zone.name).to_date > shipment.pickup_on
          str << '<tr class="table-danger">'
        elsif DateTime.current.in_time_zone(shipment.shipper_address.time_zone.name).to_date < shipment.pickup_on
          str << '<tr class="table-info">'
        end
      elsif shipment.pending_departure?
        str << '<tr class="table-danger">'
      else
        shipment.late? || !shipment.canceled_at.blank? || shipment.dispatch_incomplete? || (!shipment.picked_up_at.blank? && shipment.missing_delivery_eta_on?) ? str << '<tr class="table-warning">' : str << '<tr>'
      end

      td_names.each do |td_name|
        td_names_map.each do |td_names_map_line|
          next unless td_names_map_line[0] == td_name

          str << render(
            partial: "broker/shipments/show_many_td_#{td_names_map_line[0]}",
            formats: %i[html],
            locals: { shipment: shipment }
          )
        end
      end
      str << '</tr>'
    end

    str << '</tbody>'
    str << '</table>'
    str << '</div>'
    str.html_safe
  end
=end

  def default_packaging_id
    @default_packaging_id ||= Packaging.find_by_name('pallet')&.id
  end
end
