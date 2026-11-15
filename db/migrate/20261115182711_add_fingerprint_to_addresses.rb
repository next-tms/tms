class AddFingerprintToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :fingerprint, :string
  end
end
