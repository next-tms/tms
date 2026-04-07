# == Schema Information
#
# Table name: contacts
#
# @!attribute id
#   @return []
# @!attribute comments
#   @return [String]
# @!attribute companyable_type
#   @return [String]
# @!attribute email
#   @return [String]
# @!attribute first_name
#   @return [String]
# @!attribute job_title
#   @return [String]
# @!attribute label
#   @return [String]
# @!attribute last_name
#   @return [String]
# @!attribute mobile_phone
#   @return [String]
# @!attribute work_phone
#   @return [String]
# @!attribute companyable_id
#   @return []
#
# Indexes
#
#  idx_on_companyable_id_companyable_type_email_1de3a153e6  (companyable_id,companyable_type,email) UNIQUE
#  index_contacts_on_companyable                            (companyable_type,companyable_id)
#
FactoryBot.define do
  factory :contact do
    association :companyable, factory: %i[broker_carrier broker_customer broker].sample

    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    job_title { Faker::Job.title }
    last_name { Faker::Name.last_name }
  end
end
