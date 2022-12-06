# frozen_string_literal: true

class RenameResponseOnRatesToAPIResponse < ActiveRecord::Migration[7.0]
  def change
    rename_column :rates, :response, :api_response
  end
end
