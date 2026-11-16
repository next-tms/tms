class Broker::Carriers::BrokerCarriers::TariffsController < Broker::Carriers::BrokerCarriers::BaseController
  def show; end

  def update
    @broker_carrier.assign_attributes(tariff_params)

    unless @broker_carrier.save
      render(:show, status: :unprocessable_content)
      return
    end

    flash[:success] = t('.success')
    redirect_to([:broker, @carrier, @broker_carrier, :tariff])
  end

  private

  def tariff_params
    params.expect(
      broker_carrier: [
        {
          overlength_rules_attributes: [%i[_destroy cost id max_length min_length]],
          pricing_rules_attributes: [%i[_destroy cost_per_pallet id lane_id max_pallets min_pallets]]
        }
      ]
    )
  end
end
