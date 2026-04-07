class AddTotalToReceivables < ActiveRecord::Migration[6.1]
  def change
    add_monetize :receivables, :total, index: true
  end
end
