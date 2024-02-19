# frozen_string_literal: true

class NormalizeAddresses < ActiveRecord::Migration[7.1]
  ATTRIBUTES = %i[city ref street street2 zip_code]

  def up
    Address.find_each do |address|
      ATTRIBUTES.each do |attribute|
        address.normalize_attribute(attribute)
        next unless address.public_send("#{attribute}_changed?")

        address.update_columns(Hash[attribute, address.public_send(attribute)])
      end
    end
  end

  def down; end
end
