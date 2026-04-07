class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table(:subscriptions) do |t|
      t.datetime(:canceled_at, index: true)

      t.references(:contact, null: false, foreign_key: true)
      t.references(:record, null: false, polymorphic: true)

      t.index(%i[contact_id record_id record_type], unique: true)
      t.timestamps
    end
  end
end
