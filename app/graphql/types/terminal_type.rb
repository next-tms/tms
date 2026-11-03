module Types
  class TerminalType < Types::BaseObject
    description 'GraphQL Object for Terminal Model'

    field :address, Types::AddressType, null: false
    field :id, ID, null: false
    field :phone, String

    def address = dataloader.with(Sources::Association, Terminal, :address).load(object)
  end
end
