class AddShipmentIdUniqueIndexOnReceivables < ActiveRecord::Migration[7.0]
  def up
    remove_index :receivables, :shipment_id

    say 'remove_duplicates(:receivable)'
    Receivable.all.find_each do |receivable|
      duplicate_receivables = Receivable.where(shipment: receivable.shipment).where.not(id: receivable.id)
      next if duplicate_receivables.size.zero?

      ReceivableItem.where(receivable: duplicate_receivables).delete_all
      duplicate_receivables.delete_all
    end

    add_index :receivables, :shipment_id, unique: true
  end

  def down
    remove_index :receivables, :shipment_id
    add_index :receivables, :shipment_id
  end
end
