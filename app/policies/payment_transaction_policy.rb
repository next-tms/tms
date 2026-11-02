class PaymentTransactionPolicy < ActionPolicy::Base
  authorize :broker_carrier, optional: true
  authorize :user, optional: true

  relation_scope do |relation|
    next relation.none if broker_carrier.blank?

    relation.where(broker_carrier:).where.not(dsdc_unique_id: nil)
  end

  def manage? = broker_carrier.present?
  def view? = manage?
end
