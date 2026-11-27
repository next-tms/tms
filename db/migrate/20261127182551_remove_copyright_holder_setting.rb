class RemoveCopyrightHolderSetting < ActiveRecord::Migration[8.1]
  class Setting < ActiveRecord::Base
    self.table_name = 'settings'
  end

  def up = Setting.where(key: 'copyright_holder').delete_all
  def down = raise(ActiveRecord::IrreversibleMigration)
end
