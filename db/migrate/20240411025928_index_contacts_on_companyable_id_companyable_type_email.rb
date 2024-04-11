# frozen_string_literal: true

class IndexContactsOnCompanyableIdCompanyableTypeEmail < ActiveRecord::Migration[7.1]
  def up
    say('deduplicate(:contacts, :companyable_id, :companyable_type, :email)')
    duplicates = Contact
                 .select(:companyable_id, :companyable_type, :email)
                 .group(:companyable_id, :companyable_type, :email)
                 .having('COUNT(*) > 1')

    duplicates.each do |duplicate|
      contacts = Contact
                 .where(
                   companyable_id: duplicate.companyable_id,
                   companyable_type: duplicate.companyable_type,
                   email: duplicate.email,
                 )

      contact = contacts.last
      other_contacts = contacts.where.not(id: contact.id)

      %i[comments first_name job_title label last_name mobile_phone work_phone].each do |attribute|
        next if contact.public_send(attribute).present?

        value = other_contacts
                .where
                .not(Hash[attribute, nil])
                .pluck(attribute)
                .compact
                .first

        contact.public_send("#{attribute}=", value) if value.present?
      end
      
      BrokerCustomer.where(receivables_contact_id: other_contacts.ids).update_all(receivables_contact_id: contact.id)
      User.where(contact_id: other_contacts.ids).update_all(contact_id: contact.id)

      other_contacts.destroy_all

      contact.save! if contact.changed?
    end

    add_index(:contacts, %i[companyable_id companyable_type email], unique: true)
  end

  def down
    remove_index(:contacts, %i[companyable_id companyable_type email], unique: true)
  end
end
