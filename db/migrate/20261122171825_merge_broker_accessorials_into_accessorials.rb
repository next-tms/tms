class MergeBrokerAccessorialsIntoAccessorials < ActiveRecord::Migration[8.1]
  class Accessorial < ActiveRecord::Base; end
  class BrokerAccessorial < ActiveRecord::Base; end
  class RateAccessorial < ActiveRecord::Base; end

  def up
    add_column(:broker_accessorials, :transponder_code, :string)
    add_reference(:rate_accessorials, :broker_accessorial, foreign_key: true)

    BrokerAccessorial.reset_column_information
    RateAccessorial.reset_column_information

    transponder_codes = Transponder::ORM::Accessorial.pluck(:code)

    Accessorial.find_each do |accessorial|
      transponder_code = accessorial.freight_kit_code.presence_in(transponder_codes)
      broker_accessorials = BrokerAccessorial.where(accessorial_id: accessorial.id)
      broker_accessorials.update_all(transponder_code:)

      rate_accessorials = RateAccessorial.where(accessorial_id: accessorial.id)
      next unless rate_accessorials.exists?

      broker_accessorial = broker_accessorials.where(broker_customer_id: nil).order(:broker_only, :id).first ||
                           BrokerAccessorial.create!(
                             broker_only: false,
                             code: accessorial.code,
                             fee: accessorial.fee,
                             name: accessorial.name,
                             transponder_code:
                           )

      rate_accessorials.update_all(broker_accessorial_id: broker_accessorial.id)
    end

    remove_reference(:rate_accessorials, :accessorial, foreign_key: true, index: true, null: false)
    rename_column(:rate_accessorials, :broker_accessorial_id, :accessorial_id)
    change_column_null(:rate_accessorials, :accessorial_id, false)

    drop_table(:shipment_accessorials)
    remove_reference(:broker_accessorials, :accessorial, foreign_key: true, index: true)
    drop_table(:accessorials)

    rename_table(:broker_accessorials, :accessorials)
    add_index(:accessorials, :transponder_code)

    rename_table(:shipment_broker_accessorials, :shipment_accessorials)
    rename_column(:shipment_accessorials, :broker_accessorial_id, :accessorial_id)
  end

  def down
    rename_column(:shipment_accessorials, :accessorial_id, :broker_accessorial_id)
    rename_table(:shipment_accessorials, :shipment_broker_accessorials)

    remove_index(:accessorials, :transponder_code)
    rename_table(:accessorials, :broker_accessorials)

    create_table(:accessorials) do |t|
      t.string(:code)
      t.boolean(:fee, default: false) # rubocop:disable Rails/ThreeStateBooleanColumn
      t.string(:freight_kit_code)
      t.string(:name, index: { unique: true })
      t.timestamps
    end

    add_reference(:broker_accessorials, :accessorial, foreign_key: true)

    create_table(:shipment_accessorials) do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references(:accessorial, foreign_key: true, null: false)
      t.references(:shipment, foreign_key: true, null: false)
    end

    rename_column(:rate_accessorials, :accessorial_id, :broker_accessorial_id)
    add_reference(:rate_accessorials, :accessorial, foreign_key: true)

    BrokerAccessorial.reset_column_information
    RateAccessorial.reset_column_information

    [BrokerAccessorial.where(broker_customer_id: nil), BrokerAccessorial.where.not(broker_customer_id: nil)].each do |scope|
      scope.order(:broker_only, :id).each { |broker_accessorial| restore_accessorial(broker_accessorial) }
    end

    change_column_null(:rate_accessorials, :accessorial_id, false)
    remove_reference(:rate_accessorials, :broker_accessorial, foreign_key: { to_table: :broker_accessorials }, index: true)
    remove_column(:broker_accessorials, :transponder_code)
  end

  private

  def restore_accessorial(broker_accessorial)
    broker_accessorials = BrokerAccessorial.where(id: broker_accessorial.id)
    if broker_accessorial.transponder_code?
      broker_accessorials = broker_accessorials.or(BrokerAccessorial.where(transponder_code: broker_accessorial.transponder_code))
    end
    return if broker_accessorials.where.not(accessorial_id: nil).exists?
    return unless restorable?(broker_accessorial)

    name = broker_accessorial.name
    name = "#{name} (#{broker_accessorial.id})" if Accessorial.exists?(name:)
    accessorial = Accessorial.create!(
      code: broker_accessorial.code,
      fee: broker_accessorial.fee,
      freight_kit_code: broker_accessorial.transponder_code,
      name:
    )

    broker_accessorials.update_all(accessorial_id: accessorial.id)
    RateAccessorial.where(broker_accessorial_id: broker_accessorials.select(:id)).update_all(accessorial_id: accessorial.id)
  end

  def restorable?(broker_accessorial)
    broker_accessorial.transponder_code? || RateAccessorial.exists?(broker_accessorial_id: broker_accessorial.id)
  end
end
