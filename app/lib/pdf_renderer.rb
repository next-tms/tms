# frozen_string_literal: true

class PdfRenderer
  attr_reader :html

  def initialize(domain:, shipment:, view:)
    @html = ApplicationController.new.render_to_string(
      partial: view,
      formats: %i[pdf],
      locals: { domain:, shipment: }
    )
  end

  def data
    return @data if @data.present?

    result = Gotenberg::Chromium.call(gotenberg_url) { |doc| doc.html(html) }

    raise result.exception unless result.success?

    @data = result.to_binary
  end

  private

  def gotenberg_url
    ENV.fetch('GOTENBERG_URL', 'http://localhost:3001')
  end
end
