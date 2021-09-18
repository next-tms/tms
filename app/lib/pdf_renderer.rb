class PdfRenderer
  attr_accessor :data, :html

  def initialize(domain:, shipment:, view:)
    @html = ApplicationController.new.render_to_string(
      partial: view,
      formats: %i[pdf],
      locals: { domain: domain, shipment: shipment }
    )

    @data = WickedPdf.new.pdf_from_string(@html, page_size: 'Letter')
  end
end
