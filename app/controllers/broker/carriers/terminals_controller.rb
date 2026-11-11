class Broker::Carriers::TerminalsController < Broker::Carriers::BaseController
  FILTER = 'address_region_iso31662_or_address_city_or_address_street_or_address_zip_code_i_cont'.freeze

  def index
    @q = @carrier.terminals.ransack(query, auth_object: current_user)
    @pagy, @terminals = pagy(@q.result)
    @nearby_terminals = Carrier.where(id: @carrier.id).terminals_in(city: params[:city], state: params[:state]) if params[:city].present?
  end

  private

  def set_carrier = @carrier = Carrier.find(params.expect(:carrier_id))

  def query
    query = params[:q]&.to_unsafe_h.to_h
    filter = query.delete(FILTER)
    return query if filter.blank?

    region_iso31662s = Transponder::ORM::Region.all.select { |region| region.name.downcase.include?(filter.downcase) }.map(&:iso31662)
    query.merge(g: [{ m: 'or', FILTER => filter, address_region_iso31662_in: region_iso31662s }])
  end
end
