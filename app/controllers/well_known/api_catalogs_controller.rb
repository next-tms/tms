class WellKnown::APICatalogsController < ActionController::API
  CACHE_FOR = 1.hour
  CONTENT_TYPE = 'application/linkset+json; profile="https://www.rfc-editor.org/info/rfc9727"'.freeze

  def show
    expires_in(CACHE_FOR, public: true)
    response.headers['Link'] = %(<#{request.url}>; rel="api-catalog")

    render(content_type: CONTENT_TYPE)
  end
end
