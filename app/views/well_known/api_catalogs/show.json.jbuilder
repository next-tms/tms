apis = [
  { anchor: "#{request.base_url}/api/v1", service_doc: 'https://documenter.getpostman.com/view/1985869/TWDWJch4' },
  { anchor: "#{request.base_url}/api/dsdc", service_doc: 'https://dsdcapis.github.io/less-than-truckload/' },
  { anchor: graphql_url, service_doc: graphiql_url }
]

json.linkset apis do |api|
  json.anchor api[:anchor]

  json.set! 'service-doc' do
    json.array! [api[:service_doc]] do |href|
      json.href href
      json.type 'text/html'
    end
  end
end
