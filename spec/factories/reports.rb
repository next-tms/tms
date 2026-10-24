FactoryBot.define do
  factory :report do
    columns { [ 'load_id' ] }
    created_by { create(:broker_user) }
    record_type { 'Shipment' }
    sequence(:name) { |number| "Report #{number}" }
  end
end
