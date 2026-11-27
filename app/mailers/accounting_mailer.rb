class AccountingMailer < ApplicationMailer
  default reply_to: -> { email_address_with_name(Setting.customer_service_email!, Setting.value!(:name)) }
  helper :application, :date_time

  def unknown_customers(broker_customers:)
    users = User.active.where(id: User.broker.with_role('accounts-receivable').ids + User.broker.with_role('root').ids)

    @broker_customers = broker_customers.includes(:customer).order('customers.name')

    users.find_each do |user|
      @user = user

      mail(to: @user.email)
    end
  end
end
