# frozen_string_literal: true

module GraphQLClient
  class Transponder::Query::FetchDocument
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query(
          $carrier: CarrierInput!,
          $documentType: DocumentCategory!,
          $trackingNumber: String!,
        ) {
          fetchDocument(
            carrier: $carrier,
            documentType: $documentType,
            trackingNumber: $trackingNumber
          ) {
            document {
              contentType
              dataBase64
            }
            request
            error
          }
        }
    GRAPHQL
  end
end
