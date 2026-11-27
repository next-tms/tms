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

  def stub_transponder_matching_lanes(*lane_ids, errors: nil)
    original_hash = { 'data' => { 'fetchCarriers' => [{ 'matchingLanes' => lane_ids.map { |lane_id| { 'id' => lane_id } } }] } }
    original_hash = { 'errors' => errors } if errors.present?
    response = instance_double(GraphQL::Client::Response, original_hash:)

    allow(GraphQLClient::Transponder::Client)
      .to(receive(:query).with(GraphQLClient::Transponder::Query::FetchMatchingLanes::DETAILS, variables: anything).and_return(response))
  end

  def stub_transponder_serve(serve, errors: nil)
    original_hash = errors.present? ? { 'errors' => errors } : { 'data' => { 'fetchCarriers' => [{ 'serve' => serve }] } }
    response = instance_double(GraphQL::Client::Response, original_hash:)

    allow(GraphQLClient::Transponder::Client)
      .to(receive(:query).with(GraphQLClient::Transponder::Query::FetchServe::DETAILS, variables: anything).and_return(response))
  end
end

RSpec.configure do |config|
  config.include(TransponderCarriers)
  config.include(TransponderQueries)

  config.before do
    allow(GraphQLClient::Transponder).to(receive(:enabled?).and_return(true))
    allow(GraphQLClient::Transponder::Client).to(receive(:query).and_call_original)

    stub_transponder_carriers
  end
end
