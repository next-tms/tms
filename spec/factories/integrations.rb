FactoryBot.define do
  factory(:integration) do
    credentials do
      {
        access_token: Faker::Internet.username,
        realm_id: Faker::Number.number(digits: 16).to_s,
        refresh_token: Faker::Internet.username
      }
    end

    kind { :quickbooks }
    name { Faker::Company.name }
  end
end
