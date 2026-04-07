# == Schema Information
#
# Table name: regions
#
# @!attribute id
#   @return []
# @!attribute abbreviation
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute country_id
#   @return []
#
# Indexes
#
#  index_regions_on_abbreviation  (abbreviation)
#  index_regions_on_country_id    (country_id)
#  index_regions_on_name          (name)
#
# Foreign Keys
#
#  fk_rails_...  (country_id => countries.id)
#
class Region < ApplicationRecord
  class << self
    def ransackable_attributes(auth_object = nil)
      [ 'abbreviation', 'iso31662', 'name' ]
    end

    def ransackable_associations(auth_object = nil)
      [ 'country' ]
    end
  end

  after_save :create_area

  belongs_to :country

  has_many :addresses
  has_many :areas
  has_many :locations

  validate :iso31662_belongs_to_country

  validates :abbreviation, presence: true
  validates :iso31662, presence: true
  validates :name, presence: true

  private

  def create_area
    area = Area.new(name: "#{name}, #{country.alpha2_code}")
    area.locations.build(region: self)
    area.save!
  end

  def iso31662_belongs_to_country
    return unless [ country, iso31662 ].all?(&:present?) && !iso31662.start_with?("#{country.alpha2_code}_")

    errors.add(:iso31662, "doesn't belong to #{country.name}")
  end
end
