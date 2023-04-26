# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    l { 1 }
    w { 1 }
    h { 1 }
    nmfc { 1 }
    hazmat { false }
    refrigerated { false }
    desc { 'MyString' }
    packaging { create(:packaging) }
    weight { 1 }
    quantity { 1 }
    forced_class { 1.5 }
  end
end
