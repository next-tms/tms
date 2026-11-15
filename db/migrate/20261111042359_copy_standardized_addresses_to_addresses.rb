class CopyStandardizedAddressesToAddresses < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base
    self.table_name = 'addresses'
  end

  class StandardizedAddress < ActiveRecord::Base
    self.table_name = 'standardized_addresses'
  end

  IGNORED_TYPES = ['establishment', 'premise', 'street_address', 'subpremise'].freeze

  def up
    StandardizedAddress.find_each do |standardized_address|
      smarty = plain(standardized_address.smarty_streets_result_cached)
      spot = plain(standardized_address.google_places_spot_cached)
      metadata = smarty.is_a?(Hash) ? Hash(smarty['metadata']) : {}
      spot = {} unless spot.is_a?(Hash)

      Address.where(standardized_address_id: standardized_address.id).find_each do |address|
        address.update_columns(
          business: metadata['rdi'].presence && metadata['rdi'] == 'Commercial',
          latitude: address.latitude || standardized_address.latitude.presence,
          longitude: address.longitude || standardized_address.longitude.presence,
          permanently_closed: spot.key?('permanently_closed') ? spot['permanently_closed'] == 'true' : nil,
          po_box: metadata['record_type'].presence && metadata['record_type'] == 'P',
          residential: metadata['rdi'].presence && metadata['rdi'] == 'Residential',
          time_zone_name: standardized_address.time_zone_name.presence || address.time_zone_name,
          types: (Array(spot['types']).compact_blank - IGNORED_TYPES).uniq.sort
        )
      end
    end
  end

  def down = raise(ActiveRecord::IrreversibleMigration)

  private

  def plain(yaml) = yaml.blank? ? nil : to_plain(Psych.parse(yaml)&.root)

  def to_plain(node)
    case node
    when Psych::Nodes::Mapping then node.children.each_slice(2).to_h { |key, value| [key.value.delete_prefix(':'), to_plain(value)] }
    when Psych::Nodes::Sequence then node.children.map { |child| to_plain(child) }
    when Psych::Nodes::Scalar then node.value
    end
  end
end
