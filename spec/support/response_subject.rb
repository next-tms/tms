RSpec.shared_context('with response subject') do
  subject { response }
end

RSpec.configure do |config|
  config.include_context('with response subject', type: :controller)
  config.include_context('with response subject', type: :request)
end
