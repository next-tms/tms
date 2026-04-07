# frozen_string_literal: true

class AddUserToCommissions < ActiveRecord::Migration[6.1]
  def up
    add_reference :commissions, :user, null: true, foreign_key: true

    Commission.all.find_each do |commission|
      user_id = begin
                  BrokerCustomerSalesRep.find(commission.broker_customer_sales_rep_id)&.user_id
                rescue ActiveRecord::RecordNotFound
                  nil
                end
      next if user_id.blank?

      commission.update_columns(user_id:)
    end

    change_column_null :commissions, :user_id, false

    remove_column :commissions, :broker_customer_sales_rep_id
  end

  def down
    add_reference :commissions, :broker_customer_sales_rep, null: true, foreign_key: true

    Commission.all.find_each do |commission|
      broker_customer_sales_rep_id = begin
                                       BrokerCustomerSalesRep.where(
                                         broker_customer_id: commission.shipment.broker_customer_id,
                                         user_id: commission.user_id
                                       ).first&.id
                                     rescue ActiveRecord::RecordNotFound
                                       nil
                                     end
      next if broker_customer_sales_rep_id.blank?

      commission.update_columns(broker_customer_sales_rep_id:)
    end

    change_column_null :commissions, :broker_customer_sales_rep_id, false

    remove_column :commissions, :user_id
  end
end
