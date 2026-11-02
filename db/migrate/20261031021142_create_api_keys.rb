class CreateAPIKeys < ActiveRecord::Migration[8.1]
  def change
    create_table(:api_keys) do |t|
      t.belongs_to(:authorizable, null: false, polymorphic: true)
      t.datetime(:expires_at)
      t.datetime(:last_used_at)
      t.string(:name, null: false)
      t.belongs_to(:rolled_from, foreign_key: { to_table: :api_keys })
      t.string(:token, null: false)
      t.string(:token_digest, index: { unique: true }, null: false)
      t.string(:token_suffix, null: false)
      t.interval(:ttl)

      t.timestamps
    end
  end
end
