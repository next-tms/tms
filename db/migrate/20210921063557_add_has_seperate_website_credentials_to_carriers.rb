# frozen_string_literal: true

class AddHasSeperateWebsiteCredentialsToCarriers < ActiveRecord::Migration[6.1]
  def change
    add_column :carriers, :has_seperate_website_credentials, :boolean, default: false
  end
end
