# frozen_string_literal: true

module InterstellarApiClient
  module_function

  def build_client(broker_carrier:)
    Services::BuildApiClient.call(broker_carrier: broker_carrier)
  end

  def create_pickup(
    broker_carrier:,
    accessorials:,
    customer_reference:,
    delivery_from:,
    delivery_to:,
    destination:,
    origin:,
    packages:,
    pickup_from:,
    pickup_to:,
    receiver_contact_name:,
    receiver_name:,
    receiver_phone:,
    scac:,
    service:,
    shipper_contact_name:,
    shipper_name:,
    shipper_phone:,
    shipper_reference:,
    retry_on_timeout: false,
    return_nil_on_error: true
  )
    Services::CreatePickup.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_error: return_nil_on_error
    ).create(
      accessorials: accessorials,
      customer_reference: customer_reference,
      delivery_from: delivery_from,
      delivery_to: delivery_to,
      destination: destination,
      origin: origin,
      packages: packages,
      pickup_from: pickup_from,
      pickup_to: pickup_to,
      receiver_contact_name: receiver_contact_name,
      receiver_name: receiver_name,
      receiver_phone: receiver_phone,
      scac: scac,
      service: service,
      shipper_contact_name: shipper_contact_name,
      shipper_name: shipper_name,
      shipper_phone: shipper_phone,
      shipper_reference: shipper_reference
    )
  end

  def fetch_bol(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_bol_implemented?

    Services::FetchBol.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_error: return_nil_on_error
    ).find(tracking_number)
  end

  def fetch_pod(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_pod_implemented?

    Services::FetchPod.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_error: return_nil_on_error
    ).find(tracking_number)
  end

  def fetch_rates(broker_carrier:, origin:, destination:, packages:, accessorials:, retry_on_timeout: false, return_nil_on_error: false)
    return nil unless broker_carrier.as_interstellar_carrier&.find_rates_implemented?

    Services::FetchRates.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_error: return_nil_on_error
    ).find(origin, destination, packages, accessorials)
  end

  def fetch_tracking(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_tracking_info_implemented?

    Services::FetchTracking.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_error: return_nil_on_error
    ).find(tracking_number)
  end
end
