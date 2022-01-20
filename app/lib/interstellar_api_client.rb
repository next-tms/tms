# frozen_string_literal: true

module InterstellarApiClient
  module_function

  def build_client(broker_carrier:)
    Services::BuildApiClient.call(broker_carrier:)
  end

  def create_pickup(
    broker_carrier:,
    delivery_from:,
    delivery_to:,
    dispatcher:,
    pickup_from:,
    pickup_to:,
    scac:,
    service:,
    shipment:,
    retry_on_timeout: true,
    return_nil_on_error: false
  )
    Services::CreatePickup.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).create(
      delivery_from:,
      delivery_to:,
      dispatcher:,
      pickup_from:,
      pickup_to:,
      scac:,
      service:,
      shipment:
    )
  end

  def fetch_bol(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_bol_implemented?

    Services::FetchBol.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).find(tracking_number)
  end

  def fetch_pod(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_pod_implemented?

    Services::FetchPod.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).find(tracking_number)
  end

  def fetch_pro(broker_carrier:, pickup_number:, date:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_tracking_number_from_pickup_number_implemented?

    Services::FetchPro.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).find(pickup_number, date)
  end

  def fetch_rates(broker_carrier:, shipment:, retry_on_timeout: false, return_nil_on_error: false)
    return nil unless broker_carrier.as_interstellar_carrier&.find_rates_implemented?

    Services::FetchRates.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).find(shipment:)
  end

  def fetch_tracking(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_error: true)
    return nil unless broker_carrier.as_interstellar_carrier&.find_tracking_info_implemented?

    Services::FetchTracking.new(
      broker_carrier:,
      retry_on_timeout:,
      return_nil_on_error:
    ).find(tracking_number)
  end
end
