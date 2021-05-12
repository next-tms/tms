# frozen_string_literal: true

class Item < ApplicationRecord
  scope :packaging, lambda { |packaging|
    where(packaging: packaging)
  }

  belongs_to :packaging
  accepts_nested_attributes_for :packaging, allow_destroy: true, reject_if: :all_blank

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :weight, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :desc, presence: true

  # Set Packaging based on names (for API)
  def packaging_name=(name)
    self.packaging = Packaging.find_by_name(name)
  end

  def packaging_name
    packaging ? packaging.name : nil
  end

  # Prettify
  before_save :prettify_desc, if: :desc_changed?

  def standard_or_smaller?
    return (long_side <= 48) if long_side

    nil
  end

  def pallet_or_crate?
    %w[crate drum pallet tote].include? packaging.name
  end

  def short_side
    if l && w && h
      return l < w ? l : w
    end

    nil
  end

  def long_side
    if l && w && h
      return l > w ? l : w
    end

    nil
  end

  def cubic_ft(rounded:)
    if l && w && h
      cubic_ft = (l * w * h).to_f / 1728
      return rounded ? ('%0.2f' % cubic_ft).to_f : cubic_ft
    end
    nil
  end

  def density(rounded:)
    if l && w && h && weight && quantity
      density = (weight.to_f / quantity) / cubic_ft(rounded: false)
      return rounded ? ('%0.2f' % density).to_f : density
    end
    nil
  end

  def sanitized_freight_class(freight_class)
    return nil unless freight_class

    valid_classes = [55, 60, 65, 70, 77.5, 85, 92.5, 100, 110, 125, 150, 175, 200, 250, 300, 400]
    if valid_classes.include? freight_class
      return freight_class.to_i == freight_class ? freight_class.to_i : freight_class
    end

    nil
  end

  def density_to_freight_class(density)
    return nil unless density
    return 400 if density < 1
    return 60 if density > 30

    density_table = [
      [1, 2, 300],
      [2, 4, 250],
      [4, 6, 175],
      [6, 8, 125],
      [8, 10, 100],
      [10, 12, 92.5],
      [12, 15, 85],
      [15, 22.5, 70],
      [22.5, 30, 65],
      [30, 35, 60]
    ]
    density_table.each do |density_row|
      return density_row[2] if (density >= density_row[0]) && (density < density_row[1])
    end
  end

  def calculated_freight_class
    sanitized_freight_class density_to_freight_class(density(rounded: false))
  end

  def forced_freight_class
    sanitized_freight_class forced_class
  end

  def display_freight_class
    if forced_class.blank?
      calculated_freight_class
    else
      sanitized_freight_class forced_class
    end
  end

  def api_freight_class(use_forced_freight_class:)
    if use_forced_freight_class
      forced_freight_class.blank? ? calculated_freight_class : forced_freight_class
    else
      calculated_freight_class.blank? ? forced_freight_class : calculated_freight_class
    end
  end

  def as_reactive_shipping_package
    HyperCarrier::Package.new(
      weight * 16,
      {
        length: l,
        width: w,
        height: h
      },
      units: :imperial
    )
  end

  private

  # Prettify
  def prettify_desc
    self.desc = desc.titleize if (desc == desc.downcase) || (desc == desc.upcase)
  end
end
