FactoryBot.define { factory(:customer) { sequence(:name) { |number| "#{Faker::Company.name} #{number}" } } }
