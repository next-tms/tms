ActionDispatch::IntegrationTest.register_encoder(:ebol, response_parser: ->(body) { JSON.parse(body) })
