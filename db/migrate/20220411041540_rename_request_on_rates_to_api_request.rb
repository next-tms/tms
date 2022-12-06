# frozen_string_literal: true

class RenameRequestOnRatesToAPIRequest < ActiveRecord::Migration[7.0]
  def change
    rename_column :rates, :request, :api_request
  end
end
