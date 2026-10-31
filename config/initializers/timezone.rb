Timezone::Lookup.config(:geonames) { |c| c.username = ENV.fetch('GEONAMES_USERNAME') }
