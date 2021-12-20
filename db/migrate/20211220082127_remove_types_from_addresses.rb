# frozen_string_literal: true

class RemoveTypesFromAddresses < ActiveRecord::Migration[6.1]
  def change
    remove_column :addresses, :types, :text
  end
end
