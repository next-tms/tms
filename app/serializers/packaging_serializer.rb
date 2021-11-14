# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute interstellar_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_interstellar_type  (interstellar_type)
#
class PackagingSerializer < ActiveModel::Serializer
  attributes :name
end
