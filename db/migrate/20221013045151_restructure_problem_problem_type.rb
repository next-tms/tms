# frozen_string_literal: true

class RestructureProblemProblemType < ActiveRecord::Migration[7.0]
  def up
    add_column :problems, :problematic_rule_code, :string, index: true

    say 'populate(:problems, :problematic_rule_code)'
    problematic_rule_codes = ProblemType
                             .all
                             .map { |problem_type| { "_#{problem_type.id}".to_sym => problem_type.code } }
                             .reduce({}, :merge)

    Problem.find_each do |problem|
      problem.update_columns(problematic_rule_code: problematic_rule_codes["_#{problem.problem_type_id}".to_sym])
    end

    change_column_null :problems, :problematic_rule_code, false

    remove_column :problems, :problem_type_id

    drop_table :problem_types
  end

  def down; end
end
