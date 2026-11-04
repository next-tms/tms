class MoveBrokerCarrierContactsToCarriers < ActiveRecord::Migration[8.1]
  class BrokerCarrier < ActiveRecord::Base
    self.table_name = 'broker_carriers'
  end

  class Comment < ActiveRecord::Base
    self.table_name = 'comments'
  end

  class Contact < ActiveRecord::Base
    self.table_name = 'contacts'
  end

  class ContactRole < ActiveRecord::Base
    self.table_name = 'contact_roles'
  end

  class DocumentPreference < ActiveRecord::Base
    self.table_name = 'document_preferences'
  end

  class Subscription < ActiveRecord::Base
    self.table_name = 'subscriptions'
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  FIELDS = ['first_name', 'job_title', 'label', 'last_name', 'mobile_phone', 'work_phone'].freeze

  def up
    carrier_ids = BrokerCarrier.pluck(:id, :carrier_id).to_h

    Contact.where(companyable_type: 'BrokerCarrier').order(:id).find_each do |contact|
      carrier_id = carrier_ids.fetch(contact.companyable_id)
      existing = existing_contact(contact.email, carrier_id)
      if existing && !linked_to_users?(contact, existing)
        next merge(contact, into: existing) if existing.id < contact.id

        merge(existing, into: contact)
        existing = nil
      end

      email = existing ? User.where(contact_id: contact.id).pick(:email) : contact.email.presence
      if existing && existing_contact(email, carrier_id)
        raise(ActiveRecord::MigrationError, "Contacts #{existing.id} and #{contact.id} share an email and both have users")
      end

      contact.update_columns(companyable_id: carrier_id, companyable_type: 'Carrier', email:)
    end
  end

  def down = raise(ActiveRecord::IrreversibleMigration)

  private

  def existing_contact(email, carrier_id)
    return if email.blank?

    Contact.where(companyable_id: carrier_id, companyable_type: 'Carrier').find_by(Contact.arel_table[:email].lower.eq(email.downcase))
  end

  def linked_to_users?(*contacts) = contacts.all? { |contact| User.exists?(contact_id: contact.id) }

  def merge(contact, into:)
    attributes = FIELDS.select { |field| into[field].blank? && contact[field].present? }.index_with { |field| contact[field] }
    attributes['comments'] = [into.comments, contact.comments].compact_blank.uniq.join("\n\n").presence
    into.update_columns(attributes)

    roles = ContactRole.where(contact_id: into.id).pluck(:role)
    ContactRole.where(contact_id: contact.id, role: roles).delete_all
    ContactRole.where(contact_id: contact.id).update_all(contact_id: into.id)

    Subscription.where(contact_id: contact.id).find_each do |subscription|
      existing = Subscription.find_by(contact_id: into.id, record_id: subscription.record_id, record_type: subscription.record_type)
      next subscription.update_columns(contact_id: into.id) unless existing

      existing.update_columns(canceled_at: nil) if subscription.canceled_at.nil?
      subscription.delete
    end

    preferences = DocumentPreference.where(contact_id: into.id).pluck(:broker_customer_id, :kind)
    DocumentPreference.where(contact_id: contact.id).find_each do |document_preference|
      key = [document_preference.broker_customer_id, document_preference.kind]
      next document_preference.delete if preferences.include?(key)

      document_preference.update_columns(contact_id: into.id)
      preferences << key
    end

    Comment.where(contact_id: contact.id).update_all(contact_id: into.id)
    User.where(contact_id: contact.id).update_all(contact_id: into.id)

    contact.delete
  end
end
