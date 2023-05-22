# frozen_string_literal: true

module PDFService
  class << self
    def gotenberg_url
      ENV.fetch('GOTENBERG_URL', 'http://localhost:4683')
    end

    def merge(*paths)
      result = Gotenberg::PdfEngines.call(ENV['GOTENBERG_URL']) { |doc| doc.merge(*paths) }

      raise result.exception unless result.success?

      result.to_binary
    end
  end
end
