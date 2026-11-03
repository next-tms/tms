class LinkCarriersToTransponder < ActiveRecord::Migration[8.1]
  def change
    add_column(:carriers, :legal_name, :string)
    add_column(:carriers, :transponder_id, :uuid)
    add_index(:carriers, :transponder_id, unique: true)

    remove_column(:carriers, :encrypted_api_key, :string)
    remove_column(:carriers, :encrypted_proxy_url, :string)
  end
end
