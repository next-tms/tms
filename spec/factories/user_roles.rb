FactoryBot.define do
  factory :user_role do
    role { create(:role) }
    user { create(:user) }
  end
end
