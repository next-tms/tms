# frozen_string_literal: true

class ChangeNMFCOnItems < ActiveRecord::Migration[7.0]
  def up
    change_column :items, :nmfc, :string
  end

  def down
    say 'convert(:items, :nmfc)'
    Item.find_each { |item| item.update_columns(nmfc: item.nmfc.split('-')[0]) }

    change_column :items, :nmfc, :integer
  end
end
