class CreateStripeAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :stripe_accounts do |t|
      t.references :broker, null: false, foreign_key: true
      t.string :encrypted_account_id

      t.timestamps
    end
  end
end
