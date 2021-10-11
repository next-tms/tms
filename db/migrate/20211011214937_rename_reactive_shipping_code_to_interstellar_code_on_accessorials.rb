# frozen_string_literal: true

class RenameReactiveShippingCodeToInterstellarCodeOnAccessorials < ActiveRecord::Migration[6.1]
  def change
    rename_column :accessorials, :reactive_shipping_code, :interstellar_code
  end
end
