# == Schema Information
#
# Table name: items
#
# @!attribute id
#   @return []
# @!attribute desc
#   @return [String]
# @!attribute declared_freight_class
#   @return [Float]
# @!attribute h
#   @return [Integer]
# @!attribute hazmat
#   @return [Boolean]
# @!attribute l
#   @return [Integer]
# @!attribute nmfc
#   @return [Integer]
# @!attribute quantity
#   @return [Integer]
# @!attribute refrigerated
#   @return [Boolean]
# @!attribute w
#   @return [Integer]
# @!attribute weight
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute packaging_id
#   @return [Integer]
#
class Item < ApplicationRecord
  FREIGHT_CLASSES = [ 55, 60, 65, 70, 77.5, 85, 92.5, 100, 110, 125, 150, 175, 200, 250, 300, 400 ]

  scope :packaging, lambda { |packaging|
    where(packaging:)
  }

  audited associated_with: :shipment

  belongs_to :packaging
  belongs_to :shipment

  validate :validate_declared_freight_class

  validates :desc, :quantity, :weight, presence: true
  validates :nmfc, allow_blank: true, format: { with: /\d{4,5}(-\d{1,2})?/, message: 'is not in the correct format' }
  validates :quantity, :weight, numericality: { only_integer: true, greater_than: 0 }

  accepts_nested_attributes_for :packaging, allow_destroy: true, reject_if: :all_blank

  # Set Packaging based on names (for API)
  def packaging_name=(name)
    self.packaging = Packaging.find_by(name:)
  end

  def packaging_name
    packaging&.name
  end

  # Prettify
  before_save :prettify_desc, if: :desc_changed?

  def standard_or_smaller?
    return (long_side <= 48) if long_side

    nil
  end

  def pallet_or_crate?
    [ 'crate', 'drum', 'pallet', 'tote' ].include?(packaging.name)
  end

  def short_side
    if l && w && h
      return [ l, w ].min
    end

    nil
  end

  def long_side
    if l && w && h
      return [ l, w ].max
    end

    nil
  end

  def cubic_ft(rounded:)
    return unless [ l, w, h ].all?(&:present?)

    length_ft = Measured::Length.new(l, :in).convert_to(:ft).value
    width_ft = Measured::Length.new(w, :in).convert_to(:ft).value
    height_ft = Measured::Length.new(h, :in).convert_to(:ft).value

    value = (length_ft * width_ft * height_ft)
    return value unless rounded

    value.ceil
  end

  def density(rounded:)
    return unless [ l, w, h, quantity ].all?(&:present?)

    value = (weight.to_f / quantity) / cubic_ft(rounded: false)
    return value unless rounded

    value.ceil
  end

  def sanitized_freight_class(freight_class)
    return if freight_class.blank?

    if FREIGHT_CLASSES.include?(freight_class)
      return freight_class.to_i if freight_class.to_i == freight_class

      return freight_class
    end

    nil
  end

  def density_to_freight_class(density)
    return unless density
    return 400 if density < 1
    return 60 if density > 30

    density_table = [
                      [ 1, 2, 300 ],
                      [ 2, 4, 250 ],
                      [ 4, 6, 175 ],
                      [ 6, 8, 125 ],
                      [ 8, 10, 100 ],
                      [ 10, 12, 92.5 ],
                      [ 12, 15, 85 ],
                      [ 15, 22.5, 70 ],
                      [ 22.5, 30, 65 ],
                      [ 30, 35, 60 ]
                    ]
    density_table.each do |density_row|
      return density_row[2] if (density >= density_row[0]) && (density < density_row[1])
    end
  end

  def calculated_freight_class
    sanitized_freight_class(density_to_freight_class(density(rounded: false)))
  end

  def declared_freight_class
    sanitized_freight_class(super)
  end

  def display_freight_class
    if declared_freight_class.blank?
      calculated_freight_class
    else
      sanitized_freight_class(declared_freight_class)
    end
  end

  def api_freight_class(use_declared_freight_class:)
    if use_declared_freight_class
      declared_freight_class.presence || calculated_freight_class
    else
      calculated_freight_class.presence || declared_freight_class
    end
  end

  def as_freight_kit_package(use_declared_freight_class:)
    FreightKit::Package.new(
      weight * 16,
      {
        length: l,
        width: w,
        height: h
      },
      packaging.freight_kit_type&.to_sym,
      declared_freight_class: api_freight_class(use_declared_freight_class:),
      description: desc,
      hazmat: hazmat?,
      nmfc: nmfc.presence,
      quantity:,
      units: :imperial,
    )
  end

  def as_graphql_input(declared_freight_classes:)
    {
      dimensions: {
        length: {
          amount: l,
          unit: 'in'
        },
        width: {
          amount: w,
          unit: 'in'
        },
        height: {
          amount: h,
          unit: 'in'
        }
      },
      packaging: packaging.freight_kit_type&.to_sym,
      options: {
        declaredFreightClass: api_freight_class(use_declared_freight_class: declared_freight_classes),
        description: desc,
        hazmat: hazmat?,
        nmfc: nmfc&.to_s,
        quantity:,
        units: :imperial
      },
      weight: {
        amount: weight,
        unit: 'lb'
      }
    }
  end

  private

  def prettify_desc
    self.desc = desc.titleize if (desc == desc.downcase) || (desc == desc.upcase)
  end

  def validate_declared_freight_class
    return if declared_freight_class.present?

    dimension_attributes = %i[l h w]
    return unless dimension_attributes.any? { |attribute| public_send("will_save_change_to_#{attribute}?") }

    missing_dimension_attributes = dimension_attributes.select { |attribute| public_send(attribute).blank? }
    return if missing_dimension_attributes.empty?

    missing_dimension_attribute_names = missing_dimension_attributes
                                        .map { |attribute| human_attribute_name(attribute).downcase }
    verb = missing_dimension_attribute_names.count > 1 ? 'are' : 'is'

    message = "can't be blank when #{missing_dimension_attribute_names.join(", ")} #{verb} blank"

    errors.add(:declared_freight_class, message)
  end
end
