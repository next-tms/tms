module ShipmentsHelper
  def shipment_show_many_table(shipments:, td_names:)
    return render('layouts/no_content').html_safe if shipments.blank?

    td_names_map = [
      %w[broker_carrier Carrier],
      %w[broker_customer Customer],
      %w[created_at Entered],
      %w[delivered_at Delivered],
      %w[delivery_by ETA],
      %w[id Load],
      %w[pickup_driver_assigned_at Asgn],
      %w[pickup_eta_at ETA],
      %w[picked_up_at Pickup],
      %w[pickup_hours_end_at Closing],
      ['pickup_on', 'Pickup By'],
      %w[pickup_confirmation Ref],
      %w[pro Pro],
      %w[promised_delivery_by Service],
      %w[receiver Consignee],
      %w[shipper Shipper],
      %w[size Size],
      %w[status Status],
      %w[total_cost Cost],
      %w[total_charges Charge]
    ]

    str = '<div class="table-responsive">'
    str << '<table class="table table-condensed table-borderless table-striped table-hover sortable">'
    str << '<thead>'
    str << '<tr>'
    td_names.each do |td_name|
      td_names_map.each do |td_names_map_line|
        str << "<th>#{td_names_map_line[1]}</th>" if td_names_map_line[0] == td_name
      end
    end
    str << '</tr>'
    str << '</thead>'
    str << '<tbody>'
    shipments.each do |shipment|
      if shipment.pending_departure?
        str << '<tr class="bg-danger">'
      else
        shipment.late? || !shipment.canceled_at.blank? || shipment.dispatch_incomplete? ? str << '<tr class="bg-warning">' : str << '<tr>'
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
end
