# frozen_string_literal: true

class AddInterstellarTypeToPackagings < ActiveRecord::Migration[6.1]
  def change
    add_column :packagings, :interstellar_type, :string
    add_index :packagings, :interstellar_type
  end
end
