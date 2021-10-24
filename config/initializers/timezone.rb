# frozen_string_literal: true

Timezone::Lookup.config(:geonames) do |c|
  c.username = ENV['GEONAMES_USERNAME']
end
