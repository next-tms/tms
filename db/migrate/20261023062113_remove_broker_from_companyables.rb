class RemoveBrokerFromCompanyables < ActiveRecord::Migration[8.1]
  class Broker < ApplicationRecord; end
  class Contact < ApplicationRecord; end
  class User < ApplicationRecord; end

  COMPANYABLE_MODELS = [Contact, User].freeze

  def up
    change_column_null(:users, :companyable_id, true)
    change_column_null(:users, :companyable_type, true)
    change_column_null(:contacts, :companyable_id, true)

    say('populate(:contacts, :companyable)')
    say('populate(:users, :companyable)')

    COMPANYABLE_MODELS.each do |model|
      model.where(companyable_type: 'Broker').update_all(companyable_id: nil, companyable_type: nil)
    end
  end

  def down
    broker = Broker.first

    if broker.present?
      say('populate(:contacts, :companyable)')
      say('populate(:users, :companyable)')

      COMPANYABLE_MODELS.each do |model|
        model.where(companyable_id: nil).update_all(companyable_id: broker.id, companyable_type: 'Broker')
      end
    end

    change_column_null(:users, :companyable_id, false)
    change_column_null(:users, :companyable_type, false)
    change_column_null(:contacts, :companyable_id, false)
  end
end
