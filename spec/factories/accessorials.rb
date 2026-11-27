FactoryBot.define do
  factory :accessorial do
    broker_only { false }
    code { 'MyString' }
    fee { false }
    name { 'MyString' }
  end
end
