class RenameInterstellarErrorClassToErrorObjectOnRates < ActiveRecord::Migration[6.1]
  def change
    rename_column :rates, :interstellar_error_class, :error_object
  end
end
