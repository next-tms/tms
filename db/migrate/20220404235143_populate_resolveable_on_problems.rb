class PopulateResolveableOnProblems < ActiveRecord::Migration[7.0]
  def up
    Problem.all.find_each do |problem|
      problem.update_columns(resolvable_id: problem.shipment_id, resolvable_type: 'Shipment')
    end
  end

  def down
    Problem.all.update_all(resolvable_id: nil, resolvable_type: nil)
  end
end
