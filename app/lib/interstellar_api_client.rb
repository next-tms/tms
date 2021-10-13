module InterstellarApiClient
  extend self

  def build_client(broker_carrier:)
    Services::BuildApiClient.call(broker_carrier: broker_carrier)
  end

  def create_pickup(broker_carrier:, origin:, destination:, packages:, accessorials:, shipper_contact_name:, shipper_name:, shipper_phone:, receiver_contact_name:, receiver_name:, receiver_phone:, retry_on_timeout: false, return_nil_on_404: false)
    Services::CreatePickup.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_404: return_nil_on_404
    ).create(
      origin: origin,
      destination: destination,
      packages: packages,
      accessorials: accessorials,
      shipper_contact_name: shipper_contact_name,
      shipper_name: shipper_name,
      shipper_phone: shipper_phone,
      receiver_contact_name: receiver_contact_name,
      receiver_name: receiver_name,
      receiver_phone: receiver_phone
    )
  end

  def fetch_bol(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_404: false)
    Services::FetchBol.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_404: return_nil_on_404
    ).find(tracking_number)
  end

  def fetch_pod(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_404: false)
    Services::FetchPod.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_404: return_nil_on_404
    ).find(tracking_number)
  end

  def fetch_rates(broker_carrier:, origin:, destination:, packages:, accessorials:, retry_on_timeout: false, return_nil_on_404: false)
    Services::FetchRates.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_404: return_nil_on_404
    ).find(origin, destination, packages, accessorials)
  end

  def fetch_tracking(broker_carrier:, tracking_number:, retry_on_timeout: false, return_nil_on_404: false)
    Services::FetchTracking.new(
      broker_carrier: broker_carrier,
      retry_on_timeout: retry_on_timeout,
      return_nil_on_404: return_nil_on_404
    ).find(tracking_number)
  end
end
