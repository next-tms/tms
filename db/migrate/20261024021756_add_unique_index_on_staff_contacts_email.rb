class AddUniqueIndexOnStaffContactsEmail < ActiveRecord::Migration[8.1]
  def change
    add_index(:contacts, :email, unique: true, where: 'companyable_id IS NULL AND companyable_type IS NULL AND email IS NOT NULL')
  end
end
