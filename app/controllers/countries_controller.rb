# frozen_string_literal: true

class CountriesController < ApplicationController
  before_action :set_country

  def show
    regions = @country.regions.order(:abbreviation).map { |r| { id: r.id, abbreviation: r.abbreviation, name: r.name } }
    country = { id: @country.id, alpha2_code: @country.alpha2_code, name: @country.name, regions: }

    respond_to do |format|
      format.json { render json: { country: }.to_json }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_country
    @country = Country.find(params[:id])
  end
end
