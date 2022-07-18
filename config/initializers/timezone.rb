# frozen_string_literal: true

Timezone::Lookup.config(:geonames) do |c|
  c.username = Rails.application.credentials.geonames.username
end
