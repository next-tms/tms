class PopulateResolveableOnProblems < ActiveRecord::Migration[7.0]
  def up
    Problem.find_each { |problem| problem.update_columns(resolvable_id: problem.shipment_id, resolvable_type: 'Shipment') }
  end

  def down
    Problem.update_all(resolvable_id: nil, resolvable_type: nil)
  end
end
