class AddVCardLogoBase64ToWebsites < ActiveRecord::Migration[5.2]
  def change
    add_column :websites, :v_card_logo_base64, :text
  end
end
