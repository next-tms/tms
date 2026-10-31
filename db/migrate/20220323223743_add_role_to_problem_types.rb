class AddRoleToProblemTypes < ActiveRecord::Migration[7.0]
  def up
    add_reference :problem_types, :role, null: true, foreign_key: true

    ar_id = Role.find_by(name: 'accounts_receivable').id
    dispatch_id = Role.find_by(name: 'dispatch').id

    ProblemType.find_by(code: 'delayed_due_to_weather').update_columns(role_id: dispatch_id)
    ProblemType.find_by(code: 'lost').update_columns(role_id: dispatch_id)
    ProblemType.find_by(code: 'receivable_missing_carrier_bol').update_columns(role_id: ar_id)
    ProblemType.find_by(code: 'receivable_missing_carrier_pod').update_columns(role_id: ar_id)

    change_column_null :problem_types, :role_id, false
  end

  def down
    remove_column :problem_types, :role_id
  end
end
