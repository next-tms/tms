# frozen_string_literal: true

class ChangeMcNumberToIntegerOnCarriers < ActiveRecord::Migration[7.0]
  def up
    change_column(:carriers, :mc_number, :integer, using: 'mc_number::integer')
  end

  def down
    change_column(:carriers, :mc_number, :string, using: 'mc_number::varchar')
  end
end
