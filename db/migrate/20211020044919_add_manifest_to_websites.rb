# frozen_string_literal: true

class AddManifestToWebsites < ActiveRecord::Migration[6.1]
  def change
    add_column :websites, :manifest, :jsonb
  end
end
