class CreateContacts < ActiveRecord::Migration[5.1]
  def change
    create_table :contacts do |t|
      t.references :broker, foreign_key: true
      t.string :first_name, required: true
      t.string :last_name, required: true
      t.string :job_title
      t.string :email
      t.string :work_phone
      t.string :mobile_phone
    end
  end
end
