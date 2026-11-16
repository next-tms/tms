class AddClientIdToAPIKeys < ActiveRecord::Migration[8.1]
  class APIKey < ActiveRecord::Base; end

  def up
    add_column(:api_keys, :client_id, :string)

    APIKey.reset_column_information
    APIKey.find_each { |api_key| api_key.update_columns(client_id: SecureRandom.hex(16)) }

    change_column_null(:api_keys, :client_id, false)
    add_index(:api_keys, :client_id, unique: true)
  end

  def down = remove_column(:api_keys, :client_id)
end
