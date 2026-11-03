module Types
  class CollectionType < Types::BaseObject
    field :page, Integer, null: false
    field :page_size, Integer, null: false
    field :pages, Integer, null: false
    field :total_items, Integer, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime
    field :version, String, null: false
  end
end
