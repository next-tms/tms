module Setting::Instigatable
  extend ActiveSupport::Concern

  included do
    SUPPRESSOR_MAPPINGS = {
      requires_charges_confirmed_on_receivables: {
        problematic_rule_code: 'missing_charges_confirmed',
        problematic_type: 'Shipment',
        suppressible_type: 'Receivable'
      }
    }.freeze

    private

    def suppressor_mappings = SUPPRESSOR_MAPPINGS.slice(key.to_sym)
  end

  class_methods do
    def instigators = where(key: SUPPRESSOR_MAPPINGS.keys)
  end

  def name = Setting.value(:name)

  def requires_charges_confirmed_on_receivables = value == true

  def shipments = Shipment.all
end
