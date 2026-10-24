FactoryBot.define do
  factory :broker_customer_sales_rep do
    broker_customer
    commission_percent { 5 }
    user { association(:broker_user) }
  end
end
