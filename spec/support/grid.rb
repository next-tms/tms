module GridQueries
  def stub_grid_query(query, original_hash)
    response = instance_double(GraphQL::Client::Response, original_hash:)

    allow(GraphQLClient::Grid::Client).to(receive(:query).with(query).and_return(response))
  end
end

module GridCountries
  FIXTURE_PATH = Rails.root.join('spec/fixtures/files/grid/fetch_countries.json')

  def stub_grid_countries(original_hash = JSON.parse(FIXTURE_PATH.read))
    stub_grid_query(GraphQLClient::Grid::Query::FetchCountries::DETAILS, original_hash)
    stub_grid_country_names(original_hash)

    Grid::ORM::Country.reset
  end

  def stub_grid_country_names(original_hash)
    countries = original_hash.dig('data', 'fetchCountries').to_a

    allow(GraphQLClient::Grid::Client)
      .to(receive(:query).with(GraphQLClient::Grid::Query::FetchCountries::NAMED, variables: anything)) do |_query, variables:|
        matches = countries.select do |country|
          country.values_at('alpha2', 'alpha3', 'name').compact.any? { |value| value.casecmp?(variables[:name]) }
        end

        instance_double(GraphQL::Client::Response, original_hash: { 'data' => { 'fetchCountries' => matches } })
      end
  end
end

RSpec.configure do |config|
  config.include(GridCountries)
  config.include(GridQueries)

  config.before do
    allow(GraphQLClient::Grid::Client).to(receive(:query).and_call_original)

    stub_grid_countries
  end
end
