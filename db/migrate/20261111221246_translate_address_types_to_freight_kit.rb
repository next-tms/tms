class TranslateAddressTypesToFreightKit < ActiveRecord::Migration[8.1]
  class Address < ActiveRecord::Base
    self.table_name = 'addresses'
  end

  def down = translate { |type| GOOGLE_TYPES.fetch(type, type) }
  def translate(&) = Address.where.not(types: []).find_each { |address| address.update_columns(types: address.types.filter_map(&).uniq) }
  def up = translate { |type| LOCATION_TYPES[type] }

  FREIGHT_KIT_TYPES = {
    'airport' => ['airport'],
    'amusement_park' => ['amusement_park', 'water_park'],
    'athletic_facility' => ['arena', 'athletic_field', 'sports_complex', 'stadium'],
    'brewery' => ['brewery'],
    'cemetery' => ['cemetery'],
    'church' => ['church', 'hindu_temple', 'mosque', 'place_of_worship', 'synagogue'],
    'convention' => ['convention_center', 'event_venue'],
    'farm' => ['farm'],
    'fitness_center' => ['fitness_center', 'gym'],
    'golf_course' => ['golf_course'],
    'government' => [
      'city_hall',
      'courthouse',
      'embassy',
      'fire_station',
      'government_office',
      'local_government_office',
      'police',
      'post_office'
    ],
    'grocery_store' => ['grocery_store', 'supermarket', 'warehouse_store'],
    'hospital' => ['general_hospital', 'hospital'],
    'hotel' => ['bed_and_breakfast', 'guest_house', 'hotel', 'inn', 'lodging'],
    'mall' => ['shopping_mall'],
    'marina' => ['marina'],
    'military_site' => ['military'],
    'motel' => ['motel'],
    'nursing_home' => ['nursing_home'],
    'park' => ['dog_park', 'national_park', 'park', 'state_park'],
    'prison' => ['prison'],
    'resort' => ['resort_hotel'],
    'restaurant' => [
      'bakery',
      'bar',
      'cafe',
      'coffee_shop',
      'fast_food_restaurant',
      'food',
      'food_court',
      'meal_takeaway',
      'pub',
      'restaurant',
      'wine_bar'
    ],
    'school' => ['preschool', 'primary_school', 'school', 'secondary_school'],
    'storage_facility' => ['storage'],
    'university' => ['university'],
    'winery' => ['winery']
  }.freeze
  GOOGLE_TYPES = FREIGHT_KIT_TYPES.to_h { |type, google_types| [type, google_types.include?(type) ? type : google_types.first] }.freeze
  LOCATION_TYPES = FREIGHT_KIT_TYPES.flat_map { |type, google_types| google_types.map { [it, type] } }.to_h.freeze
end
