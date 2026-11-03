class MoveCarrierAreasToPricingRules < ActiveRecord::Migration[8.1]
  class BrokerCarrier < ActiveRecord::Base; end
  class CarrierArea < ActiveRecord::Base; end

  class PricingRule < ActiveRecord::Base
    belongs_to :broker_carrier
    belongs_to :carrier_area, optional: true
  end

  def up
    add_reference(:pricing_rules, :from_area, foreign_key: { to_table: :areas })
    add_reference(:pricing_rules, :to_area, foreign_key: { to_table: :areas })

    PricingRule.reset_column_information

    CarrierArea.find_each do |carrier_area|
      PricingRule
        .where(carrier_area_id: carrier_area.id)
        .update_all(from_area_id: carrier_area.from_area_id, to_area_id: carrier_area.to_area_id)
    end

    change_column_null(:pricing_rules, :from_area_id, false)
    change_column_null(:pricing_rules, :to_area_id, false)

    remove_reference(:pricing_rules, :carrier_area, foreign_key: true, index: true)
    drop_table(:carrier_areas)
  end

  def down
    create_table(:carrier_areas) do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references(:carrier, foreign_key: true, null: false)
      t.references(:from_area, foreign_key: { to_table: :areas }, null: false)
      t.references(:to_area, foreign_key: { to_table: :areas }, null: false)

      t.index(%i[carrier_id from_area_id to_area_id], unique: true)
    end

    add_reference(:pricing_rules, :carrier_area, foreign_key: true)

    CarrierArea.reset_column_information
    PricingRule.reset_column_information

    PricingRule.includes(:broker_carrier).find_each do |pricing_rule|
      carrier_area = CarrierArea
                     .find_or_create_by!(
                       carrier_id: pricing_rule.broker_carrier.carrier_id,
                       from_area_id: pricing_rule.from_area_id,
                       to_area_id: pricing_rule.to_area_id
                     )
      pricing_rule.update_columns(carrier_area_id: carrier_area.id)
    end

    change_column_null(:pricing_rules, :carrier_area_id, false)

    remove_reference(:pricing_rules, :from_area, foreign_key: { to_table: :areas }, index: true)
    remove_reference(:pricing_rules, :to_area, foreign_key: { to_table: :areas }, index: true)
  end
end
