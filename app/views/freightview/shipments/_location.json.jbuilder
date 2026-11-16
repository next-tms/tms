prefix, window = Freightview::STOPS.fetch(stop)
address = shipment.public_send(:"#{prefix}_address")

json.accessorials Freightview.location_accessorials(shipment, stop) do |key|
  json.key key.to_s.dasherize
end
json.address address&.street
json.address2 address&.street2
json.city address&.city
json.closesAt Freightview.time(shipment.public_send(:"#{window}_hours_end_at"))
json.company address&.name
json.contactEmail shipment.public_send(:"#{prefix}_contact_email")
json.contactName shipment.public_send(:"#{prefix}_contact_name")
json.contactPhone shipment.public_send(:"#{prefix}_contact_phone")
json.country address&.country_alpha2&.downcase
json.opensAt Freightview.time(shipment.public_send(:"#{window}_hours_start_at"))
json.postalCode address&.zip_code
json.sequence sequence
json.shipType Freightview.ship_type(shipment, stop)&.to_s&.tr('_', ' ')
json.state address&.region_iso31662.to_s.split('-').last
json.stopDate stop == :origin ? shipment.pickup_on&.iso8601 : shipment.quoted_delivery_by&.to_date&.iso8601
json.stopDateType stop == :origin ? 'on' : 'by'
json.stopType stop == :origin ? 'pickup' : 'delivery'
json.type stop
