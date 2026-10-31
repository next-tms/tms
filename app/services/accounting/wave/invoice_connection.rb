module Accounting
  module Wave
    class InvoiceConnection < Connection
      MAX_REDIRECTS = 3

      def find_by(conditions)
        _field, value = conditions.first
        query = <<~GQL
          query Find($businessId: ID!, $invoiceNumber: String!) { business(id: $businessId) { invoices(page: 1, pageSize: 1, sort: [CREATED_AT_DESC], invoiceNumber: $invoiceNumber) { edges { node { #{record_class.selection} } } } } }
        GQL

        build(execute(query, businessId: business_id, invoiceNumber: value.to_s).dig('business', 'invoices', 'edges', 0, 'node'))
      end

      def pdf(record)
        url = execute(pdf_query, businessId: business_id, id: record.id).dig('business', 'invoice', 'pdfUrl')
        return if url.blank?

        download(url)
      end

      private

      def download(url, redirects: MAX_REDIRECTS)
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        return response.body if response.is_a?(Net::HTTPSuccess)
        return if redirects.zero? || !response.is_a?(Net::HTTPRedirection)

        download((uri + response['location']).to_s, redirects: redirects - 1)
      end

      def pdf_query = 'query Pdf($businessId: ID!, $id: ID!) { business(id: $businessId) { invoice(id: $id) { pdfUrl } } }'
    end
  end
end
