class Quote
  def or_blank(str)
    str || ''
  end

  def freight_class(item:, use_forced_freight_classes:)
    if use_forced_freight_classes
      item.forced_freight_class.blank? ? item.calculated_freight_class : item.forced_freight_class
    else
      item.calculated_freight_class.blank? ? item.forced_freight_class : item.calculated_freight_class
    end
  end

  def accessorials_to_carrier_accessorial_codes(map:, accessorials:)
    return [] if accessorials.blank?

    accessorial_codes = accessorials.map(&:code)
    carrier_accessorial_codes = []
    map.each do |map_row|
      if accessorial_codes.include? map_row[0]
        carrier_accessorial_codes << map_row[1]
      else
        next
      end
    end
    carrier_accessorial_codes.blank? ? [] : carrier_accessorial_codes.uniq
  end

  def carrier_accessorial_codes_to_accessorials(map:, carrier_accessorial_codes:)
    return [] if carrier_accessorial_codes.blank?

    accessorials = []
    map.each do |map_row|
      if carrier_accessorial_codes.include? map_row[1]
        accessorials << Accessorial.find_by_code(map_row[0])
      else
        next
      end
    end
    accessorials.blank? ? [] : accessorials.uniq
  end

  def api_user_agent
    @user_agent ||= "Liftoff <https://liftoff.rocks> Ruby/#{RUBY_VERSION} (using HTTParty/#{Gem.loaded_specs['httparty'].version}, Nokogiri/#{Gem.loaded_specs['nokogiri'].version}, Savon/#{Gem.loaded_specs['savon'].version}) #{`uname -s`.strip}/#{`uname -r`.strip} (like Unix)"
  end

  def api_greeting
    @api_greeting ||= 'Greetings from Liftoff! <https://liftoff.rocks>'
  end

  def api_quote(broker_carrier:, shipment:, use_forced_freight_classes:)
    return nil if broker_carrier.carrier.scac.blank?
    return nil if shipment.truckload?

    accessorials = shipment.accessorials
    unless shipment.assumed_accessorials.blank?
      if !shipment.accessorials.blank? && (!shipment.accessorials.include? shipment.assumed_accessorials)
        accessorials = (accessorials + shipment.assumed_accessorials)
      end
    end
    accessorials = accessorials.uniq unless accessorials.blank?

    case broker_carrier.carrier.scac.upcase
    when 'DRRQ'
      Rails.logger.info "Quoting BrokerCarrier #{broker_carrier.id}: Carrier #{broker_carrier.carrier.name} Account #{broker_carrier.account}"
      drrq_quote shipment: shipment, broker_carrier: broker_carrier, use_forced_freight_classes: use_forced_freight_classes, accessorials: accessorials
    end
  end

  def drrq_quote(accessorials:, broker_carrier:, shipment:, use_forced_freight_classes:)
    if !shipment.linear_ft.blank? && (shipment.linear_ft >= 10)
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Defer: Skipping #{broker_carrier.carrier.name}, `shipment.linear_ft >= 10`"
      return
    end

    url = Rails.env.production? ? 'https://dlsworldwideproxy.rrd.com/services' : 'https://dlsworldwideproxy-stage.rrd.com/services'
    url += '/api/v1/RateShop/RateRequest'

    auth = { username: broker_carrier.username, password: broker_carrier.password }

    items = []
    shipment.items.each do |item|
      items << {
        Name: item.desc,
        FreightClass: freight_class(item: item, use_forced_freight_classes: use_forced_freight_classes).to_f.to_s,
        Weight: item.weight,
        WeightUnits: 'lb',
        Width: item.w,
        Length: item.l,
        Height: item.h,
        DimensionUnits: 'in',
        Quantity: item.quantity,
        QuantityUnits: 'PLT' # Check this
      }
    end

    carrier_accessorials = []
    map = [
      %w[DAIR LADAIRP],
      %w[DAMU LADFAIR],
      %w[DAPP APPT],
      %w[DAPP NTFY],
      %w[DATH LADRECR],
      %w[DBRE LADWINE],
      %w[DCHU LADCHUR],
      %w[DCON CONSL],
      %w[DCON LADCONS],
      %w[DFAR LADFARM],
      %w[DGOL LADGOLF],
      %w[DGOV LADGOVE],
      %w[DGRO LADGROC],
      %w[DHOS LADHOSP],
      %w[DHOT LADRESO],
      %w[DINS IDL],
      %w[DLIF LG1],
      %w[DMAL LADMALL],
      %w[DMIL LADMILI],
      %w[DPAR LADPARK],
      %w[DPRI LADPRIS],
      %w[DRAN LADRANC],
      %w[DRES RES1],
      %w[DRST LADREST],
      %w[DRSV LADRESE],
      %w[DSCH LADSCHO],
      %w[DSTO LADMINI],
      %w[PAIR LAPAIRP],
      %w[PAMU LAPFAIR],
      %w[PATH LAPRECR],
      %w[PBRE LAPWINE],
      %w[PCHU LAPCHUR],
      %w[PCON LAPCONS],
      %w[PFAR LAPFARM],
      %w[PGOL LAPGOLF],
      %w[PGOV LAPGOVE],
      %w[PGRO LAPGROC],
      %w[PHOS LAPHOSP],
      %w[PHOT LAPRESO],
      %w[PLIF LG2],
      %w[PMAL LAPMALL],
      %w[PMIL LAPMILI],
      %w[PPAR LAPPARK],
      %w[PPRI LAPPRIS],
      %w[PRAN LAPRANC],
      %w[PRES RES2],
      %w[PRST LAPREST],
      %w[PRSV LAPRESE],
      %w[PSCH LAPSCHO],
      %w[PSTO LAPMINI]
    ]
    carrier_accessorial_codes = accessorials_to_carrier_accessorial_codes(map: map, accessorials: accessorials)
    carrier_accessorial_codes.each do |carrier_accessorial_code|
      carrier_accessorials << { ServiceCode: carrier_accessorial_code }
    end

    unless shipment.longest_dimension.blank?
      longest_dimension_ft = (shipment.longest_dimension.to_f / 12).ceil
      if longest_dimension_ft >= 30
        return nil
      elsif longest_dimension_ft >= 8
        carrier_accessorials << { ServiceCode: "OVL#{longest_dimension_ft}" }
        Rails.logger.info "Carrier overlength accessorial codes: OVL#{longest_dimension_ft}"
      end
    end

    message = {
      Constraints: {
        ServiceFlags: carrier_accessorials
      },
      Items: items,
      PickupEvent: {
        Date: (shipment.pickup_on || Date.current).in_time_zone(shipment.shipper_address.time_zone.to_s).strftime('%m/%d/%Y %I:%M:00 %p'),
        LocationCode: 'PLocationCode',
        City: or_blank(shipment.shipper_address.city).upcase,
        State: or_blank(shipment.shipper_address.state),
        Zip: shipment.shipper_address.zip_code,
        Country: 'USA'
      },
      DropEvent: {
        Date: (shipment.promised_delivery_by || Date.current + 5.days).in_time_zone(shipment.receiver_address.time_zone.to_s).strftime('%m/%d/%Y %I:%M:00 %p'),
        LocationCode: 'DLocationCode',
        City: or_blank(shipment.receiver_address.city).upcase,
        State: or_blank(shipment.receiver_address.state),
        Zip: shipment.receiver_address.zip_code,
        Country: 'USA',
        MaxPriceSheet: 6,
        ShowInsurance: false
      }
    }.to_json

    begin
      response = Rails.cache.fetch([url, message], expires: 12.hours) do
        HTTParty.post(url,
                      headers: {
                        'User-Agent' => api_user_agent,
                        'X-Greeting' => api_greeting,
                        'Accept' => 'application/json',
                        'Content-Type' => 'application/json',
                        'charset' => 'utf-8',
                        'UserName' => broker_carrier.username,
                        'ApiKey' => broker_carrier.password
                      },
                      body: message)
      end
    rescue Timeout::Error
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: Timeout (handled)"
      return nil
    rescue StandardError => e
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: #{response.inspect}" if defined?(response)
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: #{e.inspect}"
      Rails.logger.warn e.backtrace
      return nil
    end

    if response.blank?
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: Reponse is nil"
      return nil
    end

    begin
      carrier_names_and_scacs = response.inject([]) { |arr, e| arr << { carrier_name: e['CarrierName'], scac: e['Scac'] } }
      carrier_names_and_scacs.each do |carrier_name_and_scac|
        carrier = Carrier.find_by_scac(carrier_name_and_scac[:scac])
        Carrier.create name: carrier_name_and_scac[:carrier_name], scac: carrier_name_and_scac[:scac] if carrier.blank?
      end
    rescue StandardError => e
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: #{response.inspect}" if defined?(response)
      Rails.logger.warn "#{broker_carrier.carrier.name} API: Error: #{e.inspect}"
      Rails.logger.warn e.backtrace
      return nil
    end

    response.each do |response_line|
      begin
        cost = Money.new(response_line['Total'].to_f * 100)
      rescue StandardError
        return nil
      end
      next if cost == Money.new(0)

      carrier = Carrier.find_by_scac(response_line['Scac'])

      if carrier.scac == 'RETL'
        Rails.logger.warn "#{broker_carrier.carrier.name} API: Defer: Skipping #{broker_carrier.carrier.name}, poor performance"
        next
      end

      rate = Rate.new
      rate.shipment = shipment
      rate.accessorials = carrier_accessorial_codes_to_accessorials(carrier_accessorial_codes: carrier_accessorial_codes, map: map)
      rate.broker_carrier = broker_carrier
      rate.broker_customer = shipment.broker_customer
      rate.with_calculated_freight_classes = !use_forced_freight_classes
      rate.tracking_carrier = carrier
      rate.cost = cost
      rate.reference = nil
      rate.transit_days = response_line['ServiceDays'].to_i
      rate.reactive_shipping_service_type = 'standard_ltl'
      rate.request = message
      rate.response = response
      unless rate.save
        Rails.logger.error "#{broker_carrier.carrier.name} API: Error: Create Rate: #{rate.errors.full_messages}"
      end
    end
  end
end
