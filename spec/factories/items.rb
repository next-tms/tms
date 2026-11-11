FactoryBot.define do
  factory :item do
    association :packaging
    association :shipment

    declared_freight_class { [nil, Item::FREIGHT_CLASSES.sample].sample }
    desc { Faker::Lorem.words.map(&:upcase_first).join(' ') }
    hazmat { [true, false].sample }
    nmfc { [nil, rand(1000..99_999)].sample&.to_s }
    quantity { rand(1..5) }
    refrigerated { [true, false].sample }

    l { rand(1..99) }
    w { rand(1..99) }
    h { rand(1..99) }

    weight { rand(1..99) }
  end
end
