# frozen_string_literal: true

class AddIso31662ToRegions < ActiveRecord::Migration[7.0]
  def up
    add_column :regions, :iso31662, :string, index: true

    say 'populate(:regions, :iso31662)'
    Region.includes(:country).find_each do |region|
      region.update_columns(iso31662: "#{region.country.alpha2_code}_#{region.abbreviation}")
    end
    
    change_column_null :regions, :iso31662, false
  end
  
  def down
    remove_column :regions, :iso31662, :string
  end
end
