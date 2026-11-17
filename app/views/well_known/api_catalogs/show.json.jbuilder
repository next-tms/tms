apis = [
  { anchor: "#{request.base_url}/api/v1", service_doc: 'https://documenter.getpostman.com/view/1985869/TWDWJch4' },
  { anchor: "#{request.base_url}/api/dsdc", service_doc: 'https://dsdcapis.github.io/less-than-truckload/' },
  { anchor: graphql_url, service_doc: graphiql_url },
  { anchor: mcp_url, service_doc: skill_url, service_doc_type: Mime[:md].to_s }
]

json.linkset apis do |api|
  json.anchor api[:anchor]

  json.set! 'service-doc' do
    json.array! [api[:service_doc]] do |href|
      json.href href
      json.type api.fetch(:service_doc_type, Mime[:html].to_s)
    end
  end
end
