# == Schema Information
#
# Table name: items
#
# @!attribute id
#   @return []
# @!attribute desc
#   @return [String]
# @!attribute forced_class
#   @return [Float]
# @!attribute h
#   @return [Integer]
# @!attribute hazmat
#   @return [Boolean]
# @!attribute l
#   @return [Integer]
# @!attribute nmfc
#   @return [Integer]
# @!attribute quantity
#   @return [Integer]
# @!attribute refrigerated
#   @return [Boolean]
# @!attribute w
#   @return [Integer]
# @!attribute weight
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute packaging_id
#   @return [Integer]
#
class ItemSerializer < ActiveModel::Serializer
  attributes :quantity, :packaging, :desc, :l, :w, :h, :weight

  def packaging
    ActiveModel::SerializableResource.new(object.packaging)
  end
end
