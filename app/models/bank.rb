class Bank < ApplicationRecord
  include AccountingSyncable

  accounting_syncs :account, match: -> { { name: to_accounting_account.name } }

  after_commit :push_to_accounting, unless: :saved_change_to_accounting_account_id?

  enum :kind, { checking: 'checking', credit_card: 'credit_card' }

  has_many :payments, dependent: :restrict_with_error

  validates :name, presence: true

  def pretty_name
    @pretty_name ||= "#{name} — #{kind.titleize} #{account_number}"
  end

  def applicable_payment_method
    PaymentMethod.all.find { |p| p.enumerable_value == kind }
  end

  def to_accounting_account
    Accounting::Account.new(
      account_number:,
      name: [name, account_number.presence&.first(4)].compact.join(' '),
      sub_type: credit_card? ? :credit_card : :checking
    )
  end

  private

  def push_to_accounting = (PushBankToAccountingJob.perform_later(self) if Accounting.connected? && Accounting.supports?(:account))
end
