# frozen_string_literal: true

class RemoveStateFromAddresses < ActiveRecord::Migration[6.1]
  def change
    remove_column :addresses, :state, :string
  end
end
