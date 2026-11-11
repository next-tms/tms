FactoryBot.define do
  factory :contact do
    companyable { %i[broker_carrier broker_customer staff].sample.then { |kind| association(kind) unless kind == :staff } }

    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    job_title { Faker::Job.title }
    last_name { Faker::Name.last_name }
  end
end
