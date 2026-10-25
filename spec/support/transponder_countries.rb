module TransponderCountries
  FIXTURE_PATH = Rails.root.join('spec/fixtures/files/transponder/fetch_countries.json')

  def stub_transponder_countries(original_hash = JSON.parse(FIXTURE_PATH.read))
    response = instance_double(GraphQL::Client::Response, original_hash:)

    allow(GraphQLClient::Transponder::Client).to(receive(:query).and_call_original)
    allow(GraphQLClient::Transponder::Client)
      .to(receive(:query).with(GraphQLClient::Transponder::Query::FetchCountries::DETAILS).and_return(response))

    Transponder::ORM::Country.reset
  end
end

RSpec.configure do |config|
  config.include(TransponderCountries)

  config.before { stub_transponder_countries }
end
