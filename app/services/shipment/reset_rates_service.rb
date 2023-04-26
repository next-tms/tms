# Provides access to broker's Stripe API
class Shipment::ResetRatesService
  attr_reader :shipment, :force_reset

  def initialize(shipment:, force_reset: false)
    @shipment = shipment
    @force_reset = force_reset
  end

  def call
    return destroy_rates! if force_reset

    destroy_rates! if destroy?
  end

  private

  def destroy?
    return false if matching_fingerprint? || blank_calculated_and_forced_freight_classes?
    return check_by_customer_preferred_kind if customer_has_preferred_broker_carriers?

    true
  end

  def matching_fingerprint?
    shipment.rates&.first&.shipment_fingerprint == shipment.fingerprint
  end

  def blank_calculated_and_forced_freight_classes?
    shipment.calculated_freight_classes.uniq == [nil] && shipment.forced_freight_classes.uniq.blank?
  end
  
  def customer_has_preferred_broker_carriers?
    shipment.broker_customer.present? && shipment.broker_customer.preferred_broker_carriers_kind
  end

  def destroy_rates!
    return shipment.rates.destroy_all  if shipment.applied_rate.blank?

    applied_rate_and_pickups_rate_ids = [shipment.applied_rate.id] + shipment.pickups.pluck(:rate_id)  
    shipment.rates.where.not(id: applied_rate_and_pickups_rate_ids).destroy_all
  end

  def check_by_customer_preferred_kind
    case shipment.broker_customer.preferred_broker_carriers_kind
    when 'whitelist'
      (shipment.broker_customer.eligible_broker_carriers.ids - shipment.rates.pluck(:broker_carrier_id)).any?
    when 'blacklist'
      (shipment.rates.pluck(:broker_carrier_id) - shipment.broker_customer.eligible_broker_carriers.ids).any?
    end
  end
end

### Previous Logic

# reset = if @shipment.rates&.first&.shipment_fingerprint == @shipment.fingerprint
#           false
#         elsif @shipment.calculated_freight_classes.uniq == [nil] && @shipment.forced_freight_classes.uniq.nil?
#           false
#         elsif @shipment.broker_customer.present? && @shipment.broker_customer.preferred_broker_carriers_kind
#           case @shipment.broker_customer.preferred_broker_carriers_kind
#           when 'whitelist'
#             (@shipment.broker_customer.eligible_broker_carriers.ids - @shipment.rates.pluck(:broker_carrier_id)).any?
#           when 'blacklist'
#             (@shipment.rates.pluck(:broker_carrier_id) - @shipment.broker_customer.eligible_broker_carriers.ids).any?
#           end
#         else
#           true
#         end

# reset = true if !reset && params[:force].present?

# if reset
#   if @shipment.applied_rate.blank?
#     @shipment.rates.destroy_all
#   else
#     @shipment.rates.where.not(
#     id: [@shipment.applied_rate.id] + @shipment.pickups.pluck(:rate_id),
#     ).destroy_all
#   end
# end