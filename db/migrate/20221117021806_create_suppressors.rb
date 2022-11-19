# frozen_string_literal: true

class CreateSuppressors < ActiveRecord::Migration[7.0]
  def change
    create_table :suppressors do |t|
      t.references :instigator, null: false, polymorphic: true

      t.string :problematic_rule_code, index: true, null: false
      t.string :problematic_type, index: true, null: false
      t.string :suppressible_type, index: true, null: false

      t.timestamps
    end
  end
end
