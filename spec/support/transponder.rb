module TransponderQueries
  def stub_transponder_query(query, original_hash)
    response = instance_double(GraphQL::Client::Response, original_hash:)

    allow(GraphQLClient::Transponder::Client).to(receive(:query).with(query).and_return(response))
  end
end

module TransponderCarriers
  FIXTURE_PATH = Rails.root.join('spec/fixtures/files/transponder/fetch_carriers.json')

  def stub_transponder_carriers(original_hash = JSON.parse(FIXTURE_PATH.read))
    stub_transponder_query(GraphQLClient::Transponder::Query::FetchCarriers::DETAILS, original_hash)

    Transponder::ORM::Carrier.reset
  end
end

module TransponderCountries
  FIXTURE_PATH = Rails.root.join('spec/fixtures/files/transponder/fetch_countries.json')

  def stub_transponder_countries(original_hash = JSON.parse(FIXTURE_PATH.read))
    stub_transponder_query(GraphQLClient::Transponder::Query::FetchCountries::DETAILS, original_hash)
    stub_transponder_country_names(original_hash)

    Transponder::ORM::Country.reset
  end

  def stub_transponder_country_names(original_hash)
    countries = original_hash.dig('data', 'fetchCountries').to_a

    allow(GraphQLClient::Transponder::Client)
      .to(receive(:query).with(GraphQLClient::Transponder::Query::FetchCountries::NAMED, variables: anything)) do |_query, variables:|
        matches = countries.select do |country|
          country.values_at('alpha2', 'alpha3', 'name').compact.any? { |value| value.casecmp?(variables[:name]) }
        end

        instance_double(GraphQL::Client::Response, original_hash: { 'data' => { 'fetchCountries' => matches } })
      end
  end
end

RSpec.configure do |config|
  config.include(TransponderCarriers)
  config.include(TransponderCountries)
  config.include(TransponderQueries)

  config.before do
    allow(GraphQLClient::Transponder::Client).to(receive(:query).and_call_original)

    stub_transponder_carriers
    stub_transponder_countries
  end
end
