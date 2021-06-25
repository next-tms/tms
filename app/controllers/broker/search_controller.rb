# frozen_string_literal: true

class Broker::SearchController < Broker::BrokerController
  before_action :authenticate_user!
  before_action :set_search

  def search
    carriers = Carrier.where('name ilike ?', "%#{@search}%")
    broker_carriers_by_name = BrokerCarrier.none

    if current_user.has_role?('carrier_relations')
      carriers.each do |carrier|
        broker_carriers_by_name += current_user.broker.broker_carriers.where(carrier: carrier)
      end
    end

    customers = Customer.where('name ilike ?', "%#{@search}%")
    broker_customers_by_name = BrokerCustomer.none
    customers.each do |customer|
      broker_customers_by_name += current_user.broker_customers.where(customer: customer)
    end

    shipments_by_load = Shipment.where(broker_customer: [current_user.broker_customers]).where(load_id: @search)
    shipments_by_bol = Shipment.where(broker_customer: [current_user.broker_customers]).where(bol: @search)
    shipments_by_broker_notes = Shipment.where(broker_customer: [current_user.broker_customers]).where('broker_notes ilike ?', "%#{@search}%")
    shipments_by_customer_reference = Shipment.where(broker_customer: [current_user.broker_customers]).where('customer_reference ilike ?', "%#{@search}%")
    shipments_by_pro = Shipment.where(broker_customer: [current_user.broker_customers]).where('pro ilike ?', "%#{@search}%")
    shipments_by_pro += Shipment.where(broker_customer: [current_user.broker_customers]).where('tracking_carrier_pro ilike ?', "%#{@search}%")
    shipments_by_shipper_reference = Shipment.where(broker_customer: [current_user.broker_customers]).where('shipper_reference ilike ?', "%#{@search}%")
    shipments_by_customer_reference = Shipment.where(broker_customer: [current_user.broker_customers]).where('customer_reference ilike ?', "%#{@search}%")
    shipments_by_shipper_name = Shipment.where(broker_customer: [current_user.broker_customers]).where('shipper_name ilike ?', "%#{@search}%")
    shipments_by_shipper_contact_name = Shipment.where(broker_customer: [current_user.broker_customers]).where('shipper_contact_name ilike ?', "%#{@search}%")
    shipments_by_receiver_name = Shipment.where(broker_customer: [current_user.broker_customers]).where('receiver_name ilike ?', "%#{@search}%")
    shipments_by_receiver_contact_name = Shipment.where(broker_customer: [current_user.broker_customers]).where('receiver_contact_name ilike ?', "%#{@search}%")

    address_ids_by_zip_code = Address.where('zip_code ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_city_name = Address.where('city ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_street = Address.where('street ilike ?', "%#{@search}%").map(&:id)
    address_ids_by_street2 = Address.where('street2 ilike ?', "%#{@search}%").map(&:id)
    all_address_ids = address_ids_by_zip_code + address_ids_by_city_name + address_ids_by_street + address_ids_by_street2
    shipments_by_address = Shipment.where(broker_customer: [current_user.broker_customers]).where(shipper_address_id: all_address_ids) + Shipment.where(broker_customer: [current_user.broker_customers]).where(receiver_address_id: all_address_ids)

    @broker_carriers = broker_carriers_by_name
    @broker_customers = broker_customers_by_name
    @shipments = shipments_by_address + shipments_by_load + shipments_by_bol + shipments_by_broker_notes + shipments_by_pro + shipments_by_shipper_reference + shipments_by_customer_reference + shipments_by_shipper_name + shipments_by_shipper_contact_name + shipments_by_receiver_name + shipments_by_receiver_contact_name

    @broker_carriers = @broker_carriers.uniq
    @broker_customers = @broker_customers.uniq
    @shipments = @shipments.uniq
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_search
    @search = params[:q]
  end
end
