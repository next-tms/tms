class DropUserRoles < ActiveRecord::Migration[7.0]
  def change
    drop_table('user_roles', force: :cascade) do |t|
      t.bigint('user_id', null: false)
      t.bigint('role_id', null: false)
      t.datetime('created_at', null: false)
      t.datetime('updated_at', null: false)
      t.index(['role_id'], name: 'index_user_roles_on_role_id')
      t.index(['user_id'], name: 'index_user_roles_on_user_id')
    end
  end
end
