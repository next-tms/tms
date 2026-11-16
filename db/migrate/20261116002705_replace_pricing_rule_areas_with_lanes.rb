class ReplacePricingRuleAreasWithLanes < ActiveRecord::Migration[8.1]
  class Area < ActiveRecord::Base
    has_many :location_areas
    has_many :locations, through: :location_areas
  end

  class BrokerCarrier < ActiveRecord::Base
    belongs_to :carrier
  end

  class Carrier < ActiveRecord::Base; end
  class Location < ActiveRecord::Base; end

  class LocationArea < ActiveRecord::Base
    belongs_to :area
    belongs_to :location
  end

  class PricingRule < ActiveRecord::Base
    belongs_to :broker_carrier
    belongs_to :from_area, class_name: 'Area', optional: true
    belongs_to :to_area, class_name: 'Area', optional: true
  end

  def up
    add_column(:pricing_rules, :lane_id, :string)
    add_index(:pricing_rules, :lane_id)

    PricingRule.reset_column_information

    PricingRule.includes(broker_carrier: :carrier, from_area: :locations, to_area: :locations).find_each do |pricing_rule|
      lane = lane_from(pricing_rule)

      if lane.blank?
        say("Deleted pricing rule #{pricing_rule.id}: no FreightKit lane for #{pricing_rule.attributes.compact.to_json}")
        pricing_rule.delete
        next
      end

      pricing_rule.update_columns(lane_id: lane.id)
    end

    change_column_null(:pricing_rules, :lane_id, false)

    remove_reference(:pricing_rules, :from_area, foreign_key: { to_table: :areas }, index: true)
    remove_reference(:pricing_rules, :to_area, foreign_key: { to_table: :areas }, index: true)

    drop_table(:location_areas)
    drop_table(:locations)
    drop_table(:areas)
  end

  def down
    create_table(:areas) do |t|
      t.string(:name, index: true)
      t.timestamps
    end

    create_table(:locations) do |t|
      t.string(:region_iso31662, index: true, null: false)
      t.string(:zip_code, index: true)
      t.timestamps
    end

    create_table(:location_areas) do |t|
      t.references(:area, foreign_key: true, null: false)
      t.references(:location, foreign_key: true, null: false)
      t.timestamps
    end

    add_reference(:pricing_rules, :from_area, foreign_key: { to_table: :areas })
    add_reference(:pricing_rules, :to_area, foreign_key: { to_table: :areas })

    PricingRule.reset_column_information

    PricingRule.find_each do |pricing_rule|
      from_area, to_area = areas_from(pricing_rule)
      pricing_rule.update_columns(from_area_id: from_area.id, to_area_id: to_area.id)
    end

    change_column_null(:pricing_rules, :from_area_id, false)
    change_column_null(:pricing_rules, :to_area_id, false)

    remove_column(:pricing_rules, :lane_id)
  end

  private

  def area_key(area)
    regions = area.locations.map(&:region_iso31662).uniq
    return if regions.size != 1

    [*regions.sole.split('-', 2), area.locations.filter_map(&:zip_code).sort]
  end

  def areas_from(pricing_rule)
    lane = Transponder::ORM::Lane.find_by(id: pricing_rule.lane_id)
    raise(ActiveRecord::IrreversibleMigration, "No FreightKit lane #{pricing_rule.lane_id}") if lane.blank?

    [territory_area(lane.origin), territory_area(lane.destination)]
  end

  def lane_from(pricing_rule)
    carrier = pricing_rule.broker_carrier.carrier
    transponder_carrier = Transponder::ORM::Carrier.find_by(id: carrier.transponder_id) ||
                          (Transponder::ORM::Carrier.find_by(scac: carrier.scac) if carrier.scac.present?)
    keys = [area_key(pricing_rule.from_area), area_key(pricing_rule.to_area)]

    transponder_carrier&.lanes&.find { |lane| [territory_key(lane.origin), territory_key(lane.destination)] == keys }
  end

  def territory_area(territory)
    raise(ActiveRecord::IrreversibleMigration, "No region for territory #{territory}") if territory.region_abbreviation.blank?

    region_iso31662 = "#{territory.country_alpha2}-#{territory.region_abbreviation}"
    zip_codes = territory.postal_codes.presence || [nil]

    Area.includes(:locations).find { |area| area_key(area) == territory_key(territory) } ||
      Area.create!(locations: zip_codes.map { |zip_code| Location.new(region_iso31662:, zip_code:) }, name: territory.to_s)
  end

  def territory_key(territory) = [territory.country_alpha2, territory.region_abbreviation, territory.postal_codes.sort]
end
