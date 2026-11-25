FactoryBot.define do
  factory :pickup do
    dispatcher { create(:broker_user) }
    rate { create(:rate, shipment:) }
    shipment { create(:shipment) }
  end
end
