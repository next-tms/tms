class Broker::Carriers::AccountingsController < Broker::BrokerController
  before_action :authenticate_user!
  before_action -> { authorize!(current_user, to: :show?, with: BrokerPolicy) }
  before_action -> { authorize!(current_user, to: :accounts_payable_show?, with: AccountingPolicy) }

  def show
    @broker_carriers = BrokerCarrier.includes(:carrier, broker_customer: :customer).companyable_order
    @vendors = Accounting.record_class(:vendor).order(:display_name)
  end

  def update
    unless BrokerCarrier.update(accounting_params.keys, accounting_params.values).all?(&:valid?)
      flash[:error] = t('.failure')
      redirect_to(%i[broker carriers accounting])
      return
    end

    flash[:success] = t('.success')
    redirect_to(%i[broker carriers accounting])
  end

  private

  def accounting_params = params.expect(accounting: { broker_carriers: [%i[accounting_vendor_id]] }).require(:broker_carriers)
end
