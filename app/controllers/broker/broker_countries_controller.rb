class Broker::BrokerCountriesController < Broker::BrokerController
  before_action :authenticate_user!

  def create
    flash[:error] = 'Unable to add country' unless BrokerCountry.new(broker_country_params).save

    redirect_to(broker_settings_company_path)
  end

  def destroy
    BrokerCountry.find(params[:id]).destroy

    redirect_to(broker_settings_company_path)
  end

  private

  def broker_country_params = params.require(:broker_country).permit(:country_alpha2)
end
