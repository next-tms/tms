class CountriesController < ApplicationController
  before_action :set_country

  def show
    respond_to do |format|
      format.json do
        expires_in(1.day, public: true)
        fresh_when(etag: [@country.name, @regions.map { |region| [region.iso31662, region.abbreviation, region.name] }], public: true)
      end
    end
  end

  private

  def set_country
    @country = Transponder::ORM::Country.find(params[:id])
    @regions = @country.regions.order(:abbreviation)
  end
end
