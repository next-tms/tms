class AddUniquenessConstraintToFromAreaToAreaOnCarrierAreas < ActiveRecord::Migration[7.1]
  def up
    say('deduplicate(:carrier_areas, :from_area, :to_area)')
    ids = CarrierArea.all.pluck(:carrier_id)
    Carrier.distinct.where(id: ids).includes(:carrier_areas).find_each do |record|
      duplicates(record.carrier_areas, :from_area_id, :to_area_id).each { |records| deduplicate(records) }
    end

    add_index(:carrier_areas, %i[carrier_id from_area_id to_area_id], unique: true)
  end

  def down
    remove_index(:carrier_areas, %i[carrier_id from_area_id to_area_id])
  end

  private

  def deduplicate(records)
    original_record = records.first

    records.where.not(id: original_record.id).find_each do |record|
      record.pricing_rules.update_all(carrier_area_id: original_record.id)
      record.delete
    end

    original_record
  end

  def duplicates(records, *column_names)
    duplicates = records.select(*column_names).group(*column_names).having('COUNT(*) > 1')

    duplicates.map do |duplicate|
      query = column_names.index_with { |column_name| duplicate.public_send(column_name) }

      records.where(**query)
    end
  end
end
