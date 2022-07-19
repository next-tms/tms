# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Stimulus
  def money_controller_data
    { action: 'blur->money#handle', controller: 'money', 'money-target': 'input' }
  end

  def flatpickr_data(options = {})
    if options[:override].blank?
      {
        controller: 'flatpickr',
        flatpickr_date_format: 'Y-m-d'
      }.deep_merge(options)
    else
      {
        controller: 'flatpickr'
      }.deep_merge(options[:override])
    end
  end

  def flatpickr_datetime_data(_datetime, time_zone)
    if time_zone.blank?
      return flatpickr_data.deep_merge(
        flatpickr_alt_input: true,
        flatpickr_alt_format: 'Y-m-d h:i K',
        flatpickr_enable_time: true,
        flatpickr_date_format: 'Y-m-dTH:i:00-00:00'
      )
    end

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError,
            "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    formatted_offset = time_zone.formatted_offset

    flatpickr_data.deep_merge(
      flatpickr_alt_input: true,
      flatpickr_alt_format: 'Y-m-d h:i K',
      flatpickr_enable_time: true,
      flatpickr_date_format: "Y-m-dTH:i:00#{formatted_offset}"
    )
  end

  def icon(style, name, text = nil, html_options = {})
    if text.is_a?(Hash)
      html_options = text
      text = nil
    end

    content_class = "fa-#{style} fa-#{name}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class

    html = content_tag(:i, nil, html_options)
    html << ' ' << text.to_s unless text.blank?
    html
  end

  def flash_class(level)
    case level
    when 'notice' then 'info'
    when 'success' then 'success'
    when 'error' then 'danger'
    when 'alert' then 'warning'
    end
  end

  def maybe_badge(n, type: '')
    "<span class=\"badge #{type}\">#{n}</span>".html_safe if n.positive?
  end

  def pretty_date(date, time_zone)
    return nil if date.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError,
            "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    if date.instance_of?(ActiveSupport::TimeWithZone)
      if date.year == DateTime.current.year
        date.in_time_zone(time_zone.name).strftime("%m/%d %a %l:%M %p <small>#{time_zone.tzinfo.abbr}</small>").html_safe
      else
        date.in_time_zone(time_zone.name).strftime("%m/%d/%y %a %l:%M %p <small>#{time_zone.tzinfo.abbr}</small>").html_safe
      end
    elsif date.instance_of?(Date)
      if date.year == DateTime.current.year
        date.in_time_zone(time_zone.name).strftime("%m/%d %a <small>#{time_zone.tzinfo.abbr}</small>").html_safe
      else
        date.in_time_zone(time_zone.name).strftime("%m/%d/%y <small>#{time_zone.tzinfo.abbr}</small>").html_safe
      end
    end
  end

  def short_date(date, time_zone)
    return nil if date.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError,
            "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    if date.year == DateTime.current.year
      date.in_time_zone(time_zone).strftime('%m/%d').html_safe
    else
      date.in_time_zone(time_zone).strftime('%m/%d/%y').html_safe
    end
  end

  def long_date(date, time_zone)
    return nil if date.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError,
            "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    date.in_time_zone(time_zone.name).strftime('%m/%d/%y').html_safe
  end

  def maybe_in_time_zone(datetime:, time_zone:)
    return '' if datetime.blank? || time_zone.blank?

    unless time_zone.is_a?(ActiveSupport::TimeZone)
      raise ArgumentError,
            "time_zone must be an ActiveSupport::TimeZone, #{time_zone.class} provided"
    end

    datetime ? datetime.in_time_zone(time_zone.name).to_s[0..-10] : ''
  end

  def pluralize_with_delimiter(count, singular, plural = nil)
    pluralize(number_with_delimiter(count), singular, plural)
  end

  def pretty_api_error(error)
    return 'Unknown error' if error.blank?

    if error.class.name.to_s.deconstantize == 'Interstellar'
      case error.class.name.split('::').last
      when 'ExpiredCredentialsError'
        'Your username and/or password is expired'
      when 'InvalidCredentialsError'
        'Your username and/or password is incorrect'
      when 'UnserviceableAccessorialsError'
        accessorial_names = Accessorial
                            .where(interstellar_code: error.accessorials)
                            .pluck(:name)
                            .map(&:downcase)

        "Unable to service #{accessorial_names.join(', ')}"
      when 'UnserviceableError'
        error.message.blank? ? 'Carrier unable to accept this shipment' : clean_sentence(error.message)
      else
        error.message
      end
    else
      error.message
    end
  end

  def clean_sentence(str)
    str = str.split(':').last
    str = str.split.map do |word|
      word.upcase == word ? word.titleize : word.downcase
    end
    str = str.join(' ')
    str = str.squish
    str = str.strip
    str = str[0].upcase + str[1..]
    str = str[0..] if str.last == '.'
    str = str.gsub('Delivery', 'delivery')
    str.gsub('zip code', 'ZIP code')
  end

  def valid_classes
    @valid_classes ||= [55, 60, 65, 70, 77.5, 85, 92.5, 100, 110, 125, 150, 175, 200, 250, 300, 400]
  end

  def generate_qr(text)
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    barcode = Barby::QrCode.new(text, level: :q, size: 5)
    base64_output = Base64.encode64(barcode.to_png({ xdim: 5 }))
    "data:image/png;base64,#{base64_output}"
  end

  # Call Devise login form from anywhere
  # https://github.com/plataformatec/devise/wiki/How-To:-Display-a-custom-sign_in-form-anywhere-in-your-app
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def link_to_add_fields(name, f, association, classes)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id

    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render("#{association.to_s.singularize}_fields", f: builder)
    end

    link_to name, '#', class: "add-fields #{classes}", data: { id:, fields: fields.gsub("\n", '') }
  end

  def real_carrier(shipment)
    return nil if shipment.broker_carrier.blank?

    if shipment.broker_carrier.carrier.acts_as_broker
      shipment.tracking_carrier.blank? ? shipment.broker_carrier.carrier : shipment.tracking_carrier
    else
      shipment.broker_carrier.carrier
    end
  end

  def real_pickup_confirmation(shipment)
    shipment.tracking_carrier.blank? ? shipment.pickup_confirmation : shipment.tracking_carrier_pickup_confirmation
  end

  def real_pro(shipment)
    shipment.tracking_carrier.blank? ? shipment.pro : shipment.tracking_carrier_pro
  end

  def pickup_uri(shipment)
    return nil if shipment.broker_carrier.blank?

    carrier = real_carrier(shipment)
    return nil if carrier.scac.blank?

    case carrier.scac.upcase
    when 'FWDA'
      "https://www.forwardair.com/tracking?type=waybill&numbers=#{real_pickup_confirmation(shipment)}"
    when 'RDFS'
      "https://tools.rrts.com/LTLTrack/?searchValues=#{real_pickup_confirmation(shipment)}"
    when 'SMTL'
      "http://profoundui.smtl.com/profoundui/start?pgm=profoundui%2Fmwp705c&p1=+#{real_pickup_confirmation(shipment)}&l1=11&p2=none&l2=4&p3=none&l3=4&Quick_Button=Get+Pro"
    when 'TOTL'
      "https://tracking.carrierlogistics.com/scripts/tot.pol/boldetail.htm?wbtn=PRO&seskey=&nav=&language=&wpro1=#{real_pro(shipment)}"
    when 'TOQL'
      # No way to send tracking number along with GET
      'https://trax.tql.com/#/shipmenttracking'
    end
  end

  def quote_uri(shipment)
    return nil if shipment.broker_carrier.blank?
    return nil if shipment.broker_carrier.carrier.scac.blank?

    case shipment.broker_carrier.carrier.scac.upcase
    when 'RDFS'
      "https://freight.rrts.com/Tools/LTL-RateQuote/Pages/RateQuoteResult.aspx?QuoteNumber=#{shipment.quote_id}"
    when 'CNWY'
      "https://ltl.xpo.com/webapp/rating_app/RatingRS.jsp?custCode=#{shipment.broker_carrier.account}&quoteKey=#{shipment.quote_id}"
    end
  end

  def tracking_uri(shipment)
    return nil if shipment.broker_carrier.blank?

    carrier = real_carrier(shipment)
    return nil if carrier.scac.blank?

    case carrier.scac.upcase
    when 'BTVP'
      # No longer functional, loads the frame of the working link below (but fails)
      # "https://www.bestovernite.com/tracking.aspx?boereq=track&scac=&pro=#{real_pro(shipment)}"
      "https://tgif.bestovernite.com/cgi-bin/wbprotrk?wbfb=#{real_pro(shipment)}&wbscac="
    when 'CENF'
      "https://centralfreight.com/website/mf/mfInquiry.aspx?inqmode=PRO&pro=#{real_pro(shipment)}"
    when 'CLNI'
      "https://ssworldtrak.com/WebtrakWTNew/ShipInquiry/ShipInfo.aspx?OrderNo=51868&Back=QuickTrack&TrackType=HousebillNo&TrackNo=#{real_pro(shipment)}"
    when 'CNWY'
      "https://ext-web.ltl-xpo.com/public-app/shipments?referenceNumber=#{real_pro(shipment)}"
    when 'CTBV'
      "https://www.customco.com/scripts/cgiip.exe/boldetail.htm?wbtn=PRO&wpro1=#{real_pro(shipment)}"
    when 'CTII'
      "http://www.centraltransportint.com/confirm/trace.aspx?pro=#{real_pro(shipment)}"
    when 'DPHE'
      "https://portal.godependable.com/secure/ltl/tracking?pro=#{real_pro(shipment)}"
    when 'DRRQ'
      "https://dls-ww.rrd.com/Login/TrackingDetails?referenceNumer=#{real_pro(shipment)}"
    when 'EXLA'
      "https://www.estes-express.com/myestes/shipment-tracking/?type=PRO&query=#{real_pro(shipment)}"
    when 'FCSY'
      "https://tracking.carrierlogistics.com/scripts/fro.pol/boldetail.htm?wbtn=PRO&wpro1=#{real_pro(shipment)}"
    when 'FWDA'
      "https://www.forwardair.com/tracking?type=waybill&numbers=#{real_pro(shipment)}"
    when 'FXFE'
      "https://www.fedex.com/fedextrack/?tracknumbers=#{real_pro(shipment)}"
    when 'FXNL'
      "https://www.fedex.com/fedextrack/?tracknumbers=#{real_pro(shipment)}"
    when 'HSXF'
      "http://apps.hawaiianexpress.com/track_freight.php?prono=#{real_pro(shipment)}"
    when 'NUMK'
      "http://tracking.numarktransportation.net/cgibin/wbprotrk?wbfb=#{real_pro(shipment)}&wbscac=&idbutton=Trace"
    when 'OTCL'
      "https://www.ontrac.com/trackingresults.asp?tracking_number=#{real_pro(shipment)}"
    when 'PYLE'
      "https://www.aduiepyle.com/LTL/ShipmentTracking?Pro=#{real_pro(shipment)}"
    when 'RDFS'
      "https://tools.rrts.com/LTLTrack/?searchValues=#{real_pro(shipment)}"
    when 'RETL'
      "http://public.reddawayregional.com/shipmentStatus/track?proNumber=#{real_pro(shipment)}"
    when 'RNLO'
      "https://www.rlcarriers.com/freight/shipping/shipment-tracing?pro=#{real_pro(shipment)}&docType=PRO&source=web"
    when 'RDWY'
      "https://my.yrc.com/tools/track/shipments?referenceNumberType=PRO&referenceNumber=#{real_pro(shipment)}"
    when 'SAIA'
      "https://www.saia.com/track/details;pro=#{real_pro(shipment)}"
    when 'SEFL'
      "https://www.sefl.com/webconnect/tracing?Type=PN&RefNum1=#{real_pro(shipment)}"
    when 'SMTL'
      "http://profoundui.smtl.com/profoundui/start?pgm=profoundui%2Fmwp705c&p1=+#{real_pro(shipment)}&l1=11&p2=none&l2=4&p3=none&l3=4&Quick_Button=Get+Pro"
    when 'TOTL'
      "https://tracking.carrierlogistics.com/scripts/tot.pol/boldetail.htm?wbtn=PRO&seskey=&nav=&language=&wpro1=#{real_pro(shipment)}"
    when 'TOQL'
      # No way to send tracking number along with GET
      'https://trax.tql.com/#/shipmenttracking'
    when 'TXWL'
      "https://www.alohafreight.com/cgi-bin/fccgi.exe?w3exec=aff.display.pro&pn=#{real_pro(shipment)}&w3serverpool=default"
    when 'UPGF'
      "https://www.ups.com/track?loc=en_US&tracknum=#{real_pro(shipment)}&requester=WT/trackdetails"
    when 'VSXP'
      "https://vsxp.com/DesktopDefault.aspx?&tabid=77&_p=#{real_pro(shipment)}"
    when 'WRDS'
      "http://tracking.wrds.com/zTrack2.aspx?ProNumber=#{real_pro(shipment)}"
    when 'XGSI'
      "https://www.xgsi.com/common/xpresstrace.aspx?numbers=#{real_pro(shipment)}"
    end
  end

  def pod_uri(shipment)
    return nil if shipment.broker_carrier.blank?
    return nil if shipment.broker_carrier.carrier.scac.blank?

    case shipment.broker_carrier.carrier.scac.upcase
    when 'CNWY'
      "https://ltl.xpo.com/webapp/imaging_app/imageretrieverequest.do?dest=fastdocview&PRO1=#{shipment.pro}&DocType1=DR"
    when 'RDFS'
      "https://tools.rrts.com/LTLTrack/Home/ShowImage?proNumber=#{shipment.pro}&imageType=POD"
    end
  end
end
