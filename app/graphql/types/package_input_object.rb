module Types
  class PackageInputObject < Types::BaseInputObject
    MAX_UNITS = 1_000

    description 'GraphQL Input Object for Package Arguments'

    argument :declared_freight_class, Float, required: false
    argument :description, String, default_value: 'Freight', replace_null_with_default: true, required: false
    argument :hazmat, Boolean, default_value: false, replace_null_with_default: true, required: false
    argument :height, Integer, description: 'Inches', required: false
    argument :length, Integer, description: 'Inches', required: false
    argument :nmfc, String, required: false
    argument :packaging, Types::PackagingEnum, default_value: 'pallet', replace_null_with_default: true, required: false
    argument :quantity, Integer, required: true, validates: { numericality: { greater_than: 0, less_than_or_equal_to: MAX_UNITS } }
    argument :weight, Integer, description: 'Pounds', required: true
    argument :width, Integer, description: 'Inches', required: false

    def item_attributes
      {
        declared_freight_class:,
        desc: description,
        h: height,
        hazmat:,
        l: length,
        nmfc:,
        packaging: Packaging.find_by(freight_kit_type: packaging),
        quantity:,
        w: width,
        weight:
      }
    end
  end
end
