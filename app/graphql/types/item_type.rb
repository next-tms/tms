module Types
  class ItemType < Types::BaseObject
    description 'GraphQL Object for Item Model'

    field :declared_freight_class, Float
    field :description, String, method: :desc
    field :hazmat, Boolean
    field :height, Integer, description: 'Inches', method: :h
    field :id, ID, null: false
    field :length, Integer, description: 'Inches', method: :l
    field :nmfc, String
    field :packaging, String
    field :quantity, Integer, null: false
    field :refrigerated, Boolean
    field :weight, Integer, description: 'Pounds', null: false
    field :width, Integer, description: 'Inches', method: :w

    def packaging = dataloader.with(Sources::Association, Item, :packaging).load(object)&.freight_kit_type
  end
end
