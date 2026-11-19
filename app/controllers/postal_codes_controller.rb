class PostalCodesController < ApplicationController
  before_action :authenticate_user!, :set_country, :set_verification

  def show
    respond_to do |format|
      format.json do
        expires_in(1.day, public: true)
        stale?(etag: [@country.alpha2, params[:id], @verification.locality, @region&.iso31662], public: true)
      end
    end
  end

  private

  def set_country = @country = Grid::ORM::Country.find(params[:country_id])

  def set_verification
    @verification = Geo.verify(postal_code: params[:id], region_code: @country.alpha2)
    raise ActiveRecord::RecordNotFound, "Couldn't find postal code #{params[:id]} in #{@country.alpha2}" if @verification&.locality.blank?

    @region = @country.regions.find_by(abbreviation: @verification.administrative_area)
  end
end
