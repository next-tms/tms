class AddUniqueIndexesForUniquenessValidations < ActiveRecord::Migration[8.1]
  class BrokerCustomer < ActiveRecord::Base; end
  class Contact < ActiveRecord::Base; end
  class ContactRole < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end
  class Subscription < ActiveRecord::Base; end
  class Suppression < ActiveRecord::Base; end
  class Suppressor < ActiveRecord::Base; end
  class User < ActiveRecord::Base; end

  BROKER_CUSTOMER_TABLES = %i[
    broker_accessorials
    broker_carriers
    broker_customer_dispatchers
    broker_customer_sales_reps
    document_preferences
    preferred_broker_carriers
    rates
    shipments
    upcharge_rules
  ].freeze
  BROKER_CUSTOMER_UNIQUE_KEYS = {
    broker_customer_dispatchers: :user_id,
    broker_customer_sales_reps: :user_id,
    preferred_broker_carriers: :broker_carrier_id
  }.freeze
  CONTACT_TABLES = %i[comments document_preferences users].freeze

  def up
    add_index :accessorials, :name, unique: true

    remove_index :broker_countries, :country_alpha2
    add_index :broker_countries, :country_alpha2, unique: true

    add_index :carriers, :mc_number, unique: true

    merge_duplicate_customers
    remove_index :customers, :name
    add_index :customers, :name, unique: true

    add_index :packagings, :name, unique: true

    remove_index :settings, :key
    add_index :settings, :key, unique: true
  end

  def down
    remove_index :accessorials, :name

    remove_index :broker_countries, :country_alpha2
    add_index :broker_countries, :country_alpha2

    remove_index :carriers, :mc_number

    remove_index :customers, :name
    add_index :customers, :name

    remove_index :packagings, :name

    remove_index :settings, :key
    add_index :settings, :key
  end

  private

  def merge_duplicate_customers
    say 'merge(:customers)'
    Customer.group(:name).having('count(*) > 1').pluck(:name).each { |name| merge_customers_named(name) }
  end

  def merge_customers_named(name)
    customers = Customer.where(name:).order(:id)
    broker_customers = BrokerCustomer.where(customer_id: customers.select(:id)).order(:id)
    broker_customer_groups = broker_customers.group_by { |broker_customer| broker_customer.accounting_customer_id.presence }.values

    broker_customer_groups.each_with_index do |(broker_customer, *duplicates), index|
      duplicates.each { |duplicate| merge_broker_customer(duplicate, into: broker_customer) }
      next if index.zero?

      suffix = broker_customer.accounting_customer_id.presence || broker_customer.id
      Customer.where(id: broker_customer.customer_id).update_all(name: available_customer_name("#{name} (#{suffix})"))
    end

    orphans = Customer.where(id: customers.ids).where.not(id: BrokerCustomer.where.not(customer_id: nil).select(:customer_id))
    orphans = orphans.where.not(id: customers.first.id) if broker_customers.none?
    orphans.delete_all
  end

  def available_customer_name(name)
    candidates = Enumerator.produce(1, &:succ).lazy.map { |number| number == 1 ? name : "#{name} #{number}" }
    candidates.find { |candidate| !Customer.exists?(name: candidate) }
  end

  def merge_broker_customer(duplicate, into:)
    BROKER_CUSTOMER_UNIQUE_KEYS.each do |table, key|
      model = model_for(table)
      model.where(broker_customer_id: duplicate.id, key => model.where(broker_customer_id: into.id).select(key)).delete_all
    end

    BROKER_CUSTOMER_TABLES.each { |table| model_for(table).where(broker_customer_id: duplicate.id).update_all(broker_customer_id: into.id) }
    User.where(companyable_type: 'BrokerCustomer', companyable_id: duplicate.id).update_all(companyable_id: into.id)
    BrokerCustomer.where(id: duplicate.id).update_all(receivables_contact_id: nil)

    Contact.where(companyable_type: 'BrokerCustomer', companyable_id: duplicate.id).find_each do |contact|
      existing = Contact.find_by(companyable_type: 'BrokerCustomer', companyable_id: into.id, email: contact.email) if contact.email
      next merge_contact(contact, into: existing) if existing

      contact.update_columns(companyable_id: into.id)
    end

    suppressors = Suppressor.where(instigator_type: 'BrokerCustomer', instigator_id: duplicate.id)
    Suppression.where(suppressor_id: suppressors.select(:id)).delete_all
    suppressors.delete_all

    BrokerCustomer.delete(duplicate.id)
  end

  def merge_contact(duplicate, into:)
    CONTACT_TABLES.each { |table| model_for(table).where(contact_id: duplicate.id).update_all(contact_id: into.id) }

    ContactRole.where(contact_id: duplicate.id).find_each do |contact_role|
      next contact_role.delete if ContactRole.exists?(contact_id: into.id, role: contact_role.role)

      contact_role.update_columns(contact_id: into.id)
    end

    Subscription.where(contact_id: duplicate.id).find_each do |subscription|
      next subscription.delete if Subscription.exists?(contact_id: into.id, **subscription.slice(:record_id, :record_type))

      subscription.update_columns(contact_id: into.id)
    end

    Contact.delete(duplicate.id)
  end

  def model_for(table) = Class.new(ActiveRecord::Base) { self.table_name = table }
end
