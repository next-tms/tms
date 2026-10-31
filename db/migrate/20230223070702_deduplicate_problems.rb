class DeduplicateProblems < ActiveRecord::Migration[7.0]
  def up
    say('deduplicate(:problems)')
    Problem.unresolved.find_each do |problem|
      begin
        problem.reload
      rescue ActiveRecord::RecordNotFound
        next
      end

      Problem
        .unresolved
        .where(problematic_rule_code: problem.problematic_rule_code, resolvable: problem.resolvable)
        .where.not(id: problem.id)
        .destroy_all
    end
  end

  def down; end
end
