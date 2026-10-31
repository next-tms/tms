# == Schema Information
#
# Table name: roles
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
FactoryBot.define { factory(:role) { name { Faker::Job.position.downcase.parameterize } } }
