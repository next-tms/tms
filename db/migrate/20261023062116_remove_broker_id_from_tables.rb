class RemoveBrokerIdFromTables < ActiveRecord::Migration[8.1]
  class Broker < ApplicationRecord; end

  COLUMNS = {
    banks: { foreign_key: true, index: true, null: false, type: :bigint },
    broker_accessorials: { foreign_key: true, index: true, null: false, type: :bigint },
    broker_carriers: { foreign_key: true, index: true, null: true, type: :integer },
    broker_countries: { foreign_key: false, index: true, null: true, type: :bigint },
    broker_customers: { foreign_key: true, index: true, null: true, type: :bigint },
    document_preferences: { foreign_key: true, index: true, null: false, type: :bigint },
    payment_transactions: { foreign_key: true, index: false, null: false, type: :bigint },
    payments: { foreign_key: true, index: false, null: false, type: :bigint },
    shipments: { foreign_key: false, index: false, null: true, type: :integer },
    stripe_accounts: { foreign_key: true, index: true, null: false, type: :bigint },
    users: { foreign_key: false, index: false, null: true, type: :integer }
  }.freeze

  def up
    add_index(:shipments, :load_id, unique: true)
    remove_index(:shipments, %i[broker_id load_id])

    COLUMNS.each do |table, options|
      remove_foreign_key(table, :brokers) if options[:foreign_key]
      remove_column(table, :broker_id)
    end
  end

  def down
    broker_id = Broker.first&.id

    COLUMNS.each do |table, options|
      say("populate(:#{table}, :broker_id)")

      add_column(table, :broker_id, options[:type], default: broker_id, null: options[:null])
      change_column_default(table, :broker_id, nil)
      add_index(table, :broker_id) if options[:index]
      add_foreign_key(table, :brokers) if options[:foreign_key]
    end

    add_index(:shipments, %i[broker_id load_id], unique: true)
    remove_index(:shipments, :load_id)
  end
end
