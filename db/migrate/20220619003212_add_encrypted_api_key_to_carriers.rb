class AddEncryptedAPIKeyToCarriers < ActiveRecord::Migration[7.0]
  def change
    add_column :carriers, :encrypted_api_key, :string
  end
end
