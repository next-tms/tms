module HyperCarrierApiClient
  extend self

  def build_client(broker_carrier:)
    Services::BuildApiClient.call(broker_carrier: broker_carrier)
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
