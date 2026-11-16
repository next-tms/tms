carrier = rate.broker_carrier.carrier.acts_as_broker? ? rate.tracking_carrier : rate.broker_carrier.carrier

json.amount rate.charge&.to_f
json.assetCarrierCode carrier&.scac
json.assetCarrierName carrier&.name
json.carrierId rate.broker_carrier_id.to_s
json.charges []
json.createdDate rate.created_at&.iso8601
json.currency rate.charge&.currency.to_s.downcase.presence
json.equipmentType 'ltl'
json.expirationDate rate.expires_at&.to_date&.iso8601
json.interline false
json.method 'api'
json.mode 'ltl'
json.paymentTerms 'outbound-prepaid'
json.pricingMethod 'contracted'
json.pricingType 'tariff'
json.providerCode carrier&.scac
json.providerName carrier&.name
json.quoteId rate.uid
json.serviceDescription rate.pretty_service_type.presence
json.serviceId rate.freight_kit_service_type
json.source 'carrier'
json.status rate.applied? ? 'awarded' : 'active'
json.transitDaysMax rate.transit_days
json.transitDaysMin rate.transit_days
