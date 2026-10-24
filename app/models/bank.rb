# == Schema Information
#
# Table name: banks
#
# @!attribute id
#   @return []
# @!attribute account_number
#   @return [String]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute accounting_account_id
#   @return [Integer]
#
class Bank < ApplicationRecord
  class << self
    def ransackable_attributes(auth_object = nil)
      [ 'name' ]
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end

  include AccountingSyncable

  accounting_syncs :account, match: -> { { name: to_accounting_account.name } }

  after_commit :push_to_accounting


  enum :kind, { checking: 'checking', credit_card: 'credit_card' }

  has_many :payments

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
      name: [ name, account_number.presence&.first(4) ].compact.join(' '),
      sub_type: credit_card? ? :credit_card : :checking,
    )
  end

  private

  def push_to_accounting = Accounting.connected? && Accounting.supports?(:account) && !!PushBankToAccountingJob.perform_later(self)
end
