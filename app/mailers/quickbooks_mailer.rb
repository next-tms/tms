class QuickbooksMailer < ActionMailer::Base
  default from: 'Next TMS <robot@tms.next-tms.com>', reply_to: 'Support — Next TMS <hello@next-tms.com>'
  helper :application

  def unknown_customers(broker_customers:)
    broker = broker_customers.first.broker
    users = User.where(id: broker.users.with_role('accounts-receivable').ids +
                           broker.users.with_role('root').ids
                      )

    @broker_customers = broker_customers.includes(:customer).order('customers.name')

    users.find_each do |user|
      @user = user

      mail(
        to: @user.email,
        reply_to: "Next TMS <hello@next-tms.com>",
        subject: 'QuickBooks Customer Sync Failure'
      )
    end
  end
end
