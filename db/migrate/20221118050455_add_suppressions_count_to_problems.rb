# frozen_string_literal: true

class AddSuppressionsCountToProblems < ActiveRecord::Migration[7.0]
  def up
    add_column :problems, :suppressions_count, :integer
add_index :problems, :suppressions_count

    say 'populate(:problems, :suppressions_count)'
    Problem.find_each { |problem| Problem.reset_counters(problem.id, :suppressions) }
  end

  def down
    remove_column :problems, :suppressions_count
  end
end
