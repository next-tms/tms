# frozen_string_literal: true

class RenameWithCalculatedFreightClassesToDeclaredFreightClassesOnRates < ActiveRecord::Migration[7.0]
  def up
    add_column(:rates, :declared_freight_classes, :boolean)

    say('populate(:rates, :declared_freight_classes)')
    # rubocop:disable Rails/SkipsModelValidations
    Rate.where(with_calculated_freight_classes: false).update_all(declared_freight_classes: true)
    Rate.where(with_calculated_freight_classes: true).update_all(declared_freight_classes: false)
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null(:rates, :declared_freight_classes, false)

    remove_column(:rates, :with_calculated_freight_classes)
  end

  def down
    add_column(:rates, :with_calculated_freight_classes, :boolean)

    say('populate(:rates, :declared_freight_classes)')
    # rubocop:disable Rails/SkipsModelValidations
    Rate.where(declared_freight_classes: false).update_all(with_calculated_freight_classes: true)
    Rate.where(declared_freight_classes: true).update_all(with_calculated_freight_classes: false)
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null(:rates, :with_calculated_freight_classes, false)

    remove_column(:rates, :declared_freight_classes)
  end
end
