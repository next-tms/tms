class AccountingMailer < ApplicationMailer
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'
  helper :application, :date_time

  def unknown_customers(broker_customers:)
    broker = broker_customers.first.broker
    users = User.active.where(id: broker.users.broker.with_role('accounts-receivable').ids +
                                  broker.users.broker.with_role('root').ids)

    @broker_customers = broker_customers.includes(:customer).order('customers.name')

    users.find_each do |user|
      @user = user

      mail(
        to: @user.email,
        reply_to: 'Next TMS <hello@next-tms.com>',
        subject: 'Accounting Customer Sync Failure'
      )
    end
  end
end
