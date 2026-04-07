module PDFService
  class << self
    def gotenberg_url
      ENV.fetch('GOTENBERG_URL', 'http://localhost:4683')
    end

    def merge(*paths)
      return File.binread(paths[0]) if paths.count == 1

      result = Gotenberg::PdfEngines.call(gotenberg_url) { |doc| doc.merge(*paths) }

      raise result.exception unless result.success?

      result.to_binary
    end
  end
end
