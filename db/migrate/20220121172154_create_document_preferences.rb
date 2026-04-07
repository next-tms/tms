class CreateDocumentPreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :document_preferences do |t|
      t.references :broker_customer, null: true, foreign_key: true
      t.references :broker, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true

      t.string :kind, index: true

      t.timestamps
    end
  end
end
