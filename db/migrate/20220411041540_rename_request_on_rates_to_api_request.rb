# frozen_string_literal: true

class RenameRequestOnRatesToApiRequest < ActiveRecord::Migration[7.0]
  def change
    rename_column :rates, :request, :api_request
  end
end
