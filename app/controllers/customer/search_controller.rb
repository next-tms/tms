# frozen_string_literal: true

class Customer::SearchController < Customer::CustomerController
  before_action :authenticate_user!
  before_action :set_search

  def search
    shipments_by_load = current_user.companyable.shipments.where(load_id: @search)
    shipments_by_bol = current_user.companyable.shipments.where(bol: @search)
    shipments_by_customer_reference = current_user.companyable.shipments.where(
      'customer_reference ilike ?',
      "%#{@search}%",
    )
    shipments_by_pro = current_user.companyable.shipments.where('pro ilike ?', "%#{@search}%")
    shipments_by_shipper_reference = current_user.companyable.shipments.where(
      'shipper_reference ilike ?',
      "%#{@search}%",
    )
    shipments_by_customer_reference = current_user.companyable.shipments.where(
      'customer_reference ilike ?',
      "%#{@search}%",
    )
    shipments_by_shipper_name = current_user.companyable.shipments.where('shipper_name ilike ?', "%#{@search}%")
    shipments_by_shipper_contact_name = current_user.companyable.shipments.where(
      'shipper_contact_name ilike ?',
      "%#{@search}%",
    )
    shipments_by_receiver_name = current_user.companyable.shipments.where('receiver_name ilike ?', "%#{@search}%")
    shipments_by_receiver_contact_name = current_user.companyable.shipments.where(
      'receiver_contact_name ilike ?',
      "%#{@search}%",
    )

    address_ids_by_zip_code = Address.where('zip_code ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_city_name = Address.where('city ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_street = Address.where('street ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_street2 = Address.where('street2 ilike ?', "%#{@search}%").map(&:id)
    all_address_ids = address_ids_by_zip_code + address_ids_by_city_name + address_ids_by_street + address_ids_by_street2
    shipments_by_address = current_user.companyable.shipments.where(shipper_address_id: all_address_ids) + current_user.companyable.shipments.where(receiver_address_id: all_address_ids)

    @shipments = shipments_by_address + shipments_by_load + shipments_by_bol + shipments_by_pro + shipments_by_shipper_reference + shipments_by_customer_reference + shipments_by_shipper_name + shipments_by_shipper_contact_name + shipments_by_receiver_name + shipments_by_receiver_contact_name

    @shipments = @shipments.uniq

    redirect_to(customer_shipment_path(@shipments.first)) and return if @shipments.size == 1
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_search
    @search = params[:q]
  end
end
