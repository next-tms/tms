module GraphQLClient
  class Transponder::Query::FetchCarriers
    DETAILS = GraphQLClient::Transponder::Client.parse(<<-GRAPHQL)
        query {
          fetchCarriers {
            actsAsBroker
            bolRequiresTrackingNumber
            checkMailingAddresses {
              ...GraphQLClient::Transponder::Fragment::CarrierAddress::DETAILS
            }
            considerBolAndPodDocumentsSame
            contacts {
              companyName
              department
              email
              fax
              id
              name
              phone
            }
            createPickupImplemented
            findRatesImplemented
            findRatesWithDeclaredValue
            headquarters {
              ...GraphQLClient::Transponder::Fragment::CarrierAddress::DETAILS
            }
            id
            lanes {
              destination {
                ...GraphQLClient::Transponder::Fragment::Territory::DETAILS
              }
              id
              origin {
                ...GraphQLClient::Transponder::Fragment::Territory::DETAILS
              }
            }
            legalName
            name
            pickupNumberIsTrackingNumber
            ratesWithExcessiveLengthFees
            requiredCredentialTypes
            scac
            terminals {
              address {
                ...GraphQLClient::Transponder::Fragment::CarrierAddress::DETAILS
              }
              id
              phone
            }
            territories {
              ...GraphQLClient::Transponder::Fragment::Territory::DETAILS
            }
            usDotNumber
            usMcNumber
            validTrackingNumberPattern
            websiteUrl
          }
        }
    GRAPHQL
  end
end
