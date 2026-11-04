class ReplaceAPIKeysAuthorizableWithUser < ActiveRecord::Migration[8.1]
  class APIKey < ActiveRecord::Base
    self.table_name = 'api_keys'
  end

  def up
    APIKey.where.not(authorizable_type: 'User').delete_all

    remove_index :api_keys, %i[authorizable_type authorizable_id], name: 'index_api_keys_on_authorizable'
    remove_column :api_keys, :authorizable_type
    rename_column :api_keys, :authorizable_id, :user_id
    add_index :api_keys, :user_id
    add_foreign_key :api_keys, :users
  end

  def down
    remove_foreign_key :api_keys, :users
    remove_index :api_keys, :user_id
    rename_column :api_keys, :user_id, :authorizable_id
    add_column :api_keys, :authorizable_type, :string

    APIKey.reset_column_information
    APIKey.update_all(authorizable_type: 'User')

    change_column_null :api_keys, :authorizable_type, false
    add_index :api_keys, %i[authorizable_type authorizable_id], name: 'index_api_keys_on_authorizable'
  end
end
