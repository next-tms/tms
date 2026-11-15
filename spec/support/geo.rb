RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:geo]

    allow(Geo).to(receive_messages(place: nil, time_zone: nil, verify: nil))
  end
end
