# frozen_string_literal: true

class QrCodeService
  class << self
    def tracking_data_uri(shipment)
      url = Rails.application.routes.url_helpers.tracking_url(
        load_id: shipment.load_id,
        host: shipment.broker.websites.first.domain
      )

      qr = RQRCode::QRCode.new(url)
      
      svg = qr.as_svg(
        color: "000",
        shape_rendering: "crispEdges",
        module_size: 4,
        standalone: true,
        use_path: true
      )
      
      "data:image/svg+xml;base64,#{Base64.encode64(svg).gsub("\n", '')}"
    end
  end
end
