class CreateDelayUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :delay_users do |t|
      t.references :delay, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
