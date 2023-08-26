module GraphqlClient
  module Queries
    class Document
      DETAILS = GraphqlClient::Transponder::Client.parse <<-'GRAPHQL'
        query($scac: String!, $documentType: DocumentCategory!, $trackingNumber: String!, $credentials: [CarrierCredentialInput!]!) {
          document(scac: $scac, documentType: $documentType, trackingNumber: $trackingNumber, credentials: $credentials) {
            request
            data
            contentType
            error
          }
        }
      GRAPHQL
    end
  end
end
