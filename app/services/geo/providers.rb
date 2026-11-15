module Geo
  module Providers
    class << self
      def all = [GoogleMaps, Grid, Smarty]
      def enabled = keys.filter_map { find(it) }.sort_by.with_index { |provider, index| [AUTHORITIES.index(provider.authority), index] }
      def find(key) = all.find { it.key == key }
      def keys = ENV.fetch('GEO_PROVIDERS').split(',').map(&:strip).compact_blank
    end

    AUTHORITIES = %i[postal_operator government certified open_data commercial local].freeze
  end
end
