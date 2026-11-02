class CreatePickupRequests < ActiveRecord::Migration[8.1]
  def change
    create_table(:pickup_requests) do |t|
      t.datetime(:accepted_pickup_at)
      t.date(:accepted_pickup_on)
      t.datetime(:canceled_at)
      t.belongs_to(:created_by, foreign_key: { to_table: :users })
      t.string(:reschedule_reason)

      t.timestamps
    end

    add_reference(:shipments, :pickup_request, foreign_key: true)
  end
end
