# frozen_string_literal: true

Timezone::Lookup.config(:geonames) do |c|
  c.username = ENV.fetch('GEONAMES_USERNAME')
end
