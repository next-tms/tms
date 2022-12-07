class AddProxyUrlOnCarrier < ActiveRecord::Migration[7.0]
  def change
    add_column :carriers, :encrypted_proxy_url, :string
  end
end
