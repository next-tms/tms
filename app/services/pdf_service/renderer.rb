module PDFService
  class Renderer
    class << self
      def call(partial, locals: {})
        new(partial, locals:).call
      end
    end

    attr_reader :html, :pdf

    def initialize(partial, locals: {})
      @html = ApplicationController
              .new
              .render_to_string(
                partial:,
                formats: %i[pdf],
                locals: locals.merge({ domain: ENV.fetch('DOMAIN') })
              )
    end

    def call
      return @pdf if @pdf.present?

      result = Gotenberg::Chromium.call(PDFService.gotenberg_url) { |doc| doc.html(html) }
      raise result.exception unless result.success?

      @pdf = result.to_binary
    end
  end
end
