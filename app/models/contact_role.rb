class ContactRole < ApplicationRecord
  belongs_to :contact

  enum :role, {
    accounting: 'accounting',
    accounts_payable: 'accounts_payable',
    accounts_receivable: 'accounts_receivable',
    appointments: 'appointments',
    carrier_relations: 'carrier_relations',
    claims: 'claims',
    controller: 'controller',
    dispatch: 'dispatch',
    quoting: 'quoting',
    root: 'root',
    sales_rep_for_all_broker_customers: 'sales_rep_for_all_broker_customers',
    sales_rep: 'sales_rep',
    tracking: 'tracking'
  }

  validates :role, presence: true, uniqueness: { scope: :contact }

  def role
    super&.to_sym
  end
end
