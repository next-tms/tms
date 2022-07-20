# frozen_string_literal: true

Timezone::Lookup.config(:geonames) do |c|
  c.username = Rails.env.test? ? 'next-tms' : Rails.application.credentials.geonames.username
end
