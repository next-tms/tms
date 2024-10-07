class ReceivablePolicy < ApplicationPolicy
  BROKER_ATTRIBUTES = %i[ authorized_at invoiced sent_at ]
  CUSTOMER_ATTRIBUTES = %i[ balance balance_cents due_by paid_at total total_cents ]

  include AuthorizedAttributablePolicy
end
