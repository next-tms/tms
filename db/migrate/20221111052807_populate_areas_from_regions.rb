class PopulateAreasFromRegions < ActiveRecord::Migration[7.0]
  def up
    say 'populate(:areas)'
    Region.includes(:country).find_each do |region|
      area = Area.new(name: "#{region.name}, #{region.country.alpha2_code}")
      area.locations.build(region:)
      area.save!
    end
  end

  def down; end
end
