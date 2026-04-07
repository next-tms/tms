class CreateContactRoles < ActiveRecord::Migration[7.0]
  def change
    create_table(:contact_roles) do |t|
      t.references(:contact, null: false, foreign_key: true)
      t.string(:role, null: false, index: true)

      t.index %i[contact_id role], unique: true
      t.timestamps
    end
  end
end
