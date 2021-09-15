module ShipmentsHelper
  def shipment_show_many_table(shipments:, td_names:)
    return render('layouts/no_content').html_safe if shipments.blank?

    td_names_map = [
      ['broker_carrier', 'Carrier', :broker_carrier_carrier_name],
      ['broker_customer', 'Customer', :broker_customer_customer_name],
      ['created_at', 'Entered', :created_at],
      ['delivered_at', 'Delivered', :delivered_at],
      ['delivery_by', 'ETA', :delivery_by],
      ['id', 'Load', :load_id],
      ['pickup_driver_assigned_at', 'Asgn', :pickup_driver_assigned_at],
      ['pickup_eta_at', 'ETA', :pickup_eta_at],
      ['picked_up_at', 'Pickup', :picked_up_at],
      ['pickup_hours_end_at', 'Closing', :pickup_hours_end_at],
      ['pickup_on', 'Pickup By', :pickup_on],
      ['pickup_confirmation', 'Ref', :pickup_confirmation],
      ['pro', 'Pro', :pro],
      ['promised_delivery_by', 'Service', nil],
      ['receiver', 'Consignee', :receiver_name],
      ['shipper', 'Shipper', :shipper_name],
      ['shipper_contact_name', 'Contact', :shipper_contact_name],
      ['size', 'Size', :items_count],
      ['status', 'Status', nil],
      ['total_cost', 'Cost', nil],
      ['total_charges', 'Charge', nil]
    ]

    str = '<div class="table-responsive">'
    str << '<table class="table table-condensed table-borderless table-striped table-hover sortable">'
    str << '<thead>'
    str << '<tr>'
    td_names.each do |td_name|
      td_names_map.each do |td_names_map_line|
        next if td_names_map_line[0] == 'broker_carrier' && controller.controller_name == 'broker_carriers'
        next if td_names_map_line[0] == 'broker_customer' && controller.controller_name == 'broker_customers'
        if defined?(@q)
          unless td_names_map_line[2].blank?
            str << "<th>#{sort_link @q, td_names_map_line[2], td_names_map_line[1]}</th>" if td_names_map_line[0] == td_name
          else
            str << "<th>#{td_names_map_line[1]}</th>" if td_names_map_line[0] == td_name
          end
        else
          str << "<th>#{td_names_map_line[1]}</th>" if td_names_map_line[0] == td_name
        end
      end
    end
    str << '</tr>'
    str << '</thead>'
    str << '<tbody>'
    shipments.each do |shipment|
      if shipment.pending_departure?
        str << '<tr class="table-danger">'
      else
        shipment.late? || !shipment.canceled_at.blank? || shipment.dispatch_incomplete? || (!shipment.picked_up_at.blank? && shipment.missing_deliver_by?) ? str << '<tr class="table-warning">' : str << '<tr>'
      end

      td_names.each do |td_name|
        td_names_map.each do |td_names_map_line|
          if td_names_map_line[0] == td_name
            str << render("broker/shipments/show_many_td_#{td_names_map_line[0]}", shipment: shipment)
          end
        end
      end
      str << '</tr>'
    end
    str << '</tbody>'
    str << '</table>'
    str << '</div>'
    str.html_safe
  end

  def default_packaging_id
    @default_packaging_id ||= Packaging.find_by_name('pallet')&.id
  end
end
