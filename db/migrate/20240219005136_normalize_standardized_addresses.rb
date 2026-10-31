class NormalizeStandardizedAddresses < ActiveRecord::Migration[7.1]
  ATTRIBUTES = %i[city postal_code street street2].freeze

  def up
    StandardizedAddress.find_each do |standardized_address|
      ATTRIBUTES.each do |attribute|
        standardized_address.normalize_attribute(attribute)
        next unless standardized_address.public_send("#{attribute}_changed?")

        standardized_address.update_columns({ attribute => standardized_address.public_send(attribute) })
      end
    end
  end

  def down; end
end
