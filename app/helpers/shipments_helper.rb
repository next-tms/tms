module ShipmentsHelper
  TABLE_DATA = {
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

  PREPENDED_TABLE_DATA = [
    display_name: 'Load',
    column_name: :load_id,
    link: true,
    path: :broker_shipment_path
  ]

  APPENDED_TABLE_DATA = [
    display_name: 'Dispatcher',
    column_name: :dispatcher_full_name,
    wrap: true
  ]

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

  def default_packaging_id
    @default_packaging_id ||= Packaging.find_by_name('pallet')&.id
  end

  def table_data_to_itereate(td_names)
    table_data = td_names.map do |td_name|
      next if td_name == controller.controller_name.singularize

      ShipmentsHelper::TABLE_DATA[td_name.to_sym]
    end.compact

    PREPENDED_TABLE_DATA + table_data + APPENDED_TABLE_DATA
  end

  def charges_confirmed_note(shipment)
    audit = shipment.audits.where("audited_changes @> ?", {"charges_confirmed" => [false, true]}.to_json ).first
    changed_by = audit.user

    "Shipment Charges Confirmed by #{changed_by.full_name} at #{(pretty_date audit.created_at, current_user.time_zone)}".html_safe
  end

  def requires_charges_confirmed_note(shipment)
    requires_by = shipment.broker.name if shipment.broker.requires_charges_confirmed_on_receivables
    requires_by = shipment.broker_customer.customer.name if shipment.broker_customer&.requires_charges_confirmed_on_receivables

    "Charges are required to be confirmed by #{requires_by} before sending Receivables to the Customer"
  end
end
