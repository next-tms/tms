# frozen_string_literal: true

class RenameForcedClassToDeclaredFreightClassOnItems < ActiveRecord::Migration[7.0]
  def change
    rename_column(:items, :forced_class, :declared_freight_class)
  end
end
