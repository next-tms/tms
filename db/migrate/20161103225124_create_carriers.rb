class CreateCarriers < ActiveRecord::Migration[5.0]
  def change
    create_table :carriers do |t|
      t.string :name
    end
  end
end
