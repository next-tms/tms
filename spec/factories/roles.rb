FactoryBot.define { factory(:role) { name { Faker::Job.position.downcase.parameterize } } }
