# frozen_string_literal: true

class CreateReceivableItems < ActiveRecord::Migration[6.1]
  def change
    create_table :receivable_items do |t|
      t.monetize :charge, index: true
      t.references :receivable, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
