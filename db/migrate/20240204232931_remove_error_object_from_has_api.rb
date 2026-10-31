class RemoveErrorObjectFromHasAPI < ActiveRecord::Migration[7.0]
  TABLES = %i[pickups rates].freeze

  def up
    TABLES.each do |table|
      say "remove(:#{table})"
      table.to_s.singularize.camelcase.constantize.where.not(error_object: nil).destroy_all

      remove_column table, :error_object, :string
    end
  end

  def down
    TABLES.each { |table| add_column table, :error_object, :string }
  end
end
