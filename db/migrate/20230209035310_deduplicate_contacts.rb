class DeduplicateContacts < ActiveRecord::Migration[7.0]
  def up
    say('deduplicate(:contacts)')
    Contact.find_each do |contact|
      begin
        contact.reload
      rescue ActiveRecord::RecordNotFound
        next
      end

      contacts = contact
                 .companyable
                 .contacts
                 .where(email: contact.email)

      if [contact.first_name, contact.last_name].all?(&:present?)
        contacts = contacts
                   .or(
                     contact
                     .companyable
                     .contacts
                     .where(email: [nil, ''])
                     .where('first_name ILIKE ?', "%#{contact.first_name.strip}%")
                     .where('last_name ILIKE ?', "%#{contact.last_name.strip}%")
                   )
      end

      next if contacts.size <= 1

      contacts = contacts.where.not(id: contact.id)
      receivables_contact = BrokerCustomer.where(receivables_contact: contacts).first
      user = User.where(contact: contacts).first

      if receivables_contact.present?
        next unless receivables_contact == contact

        if contact.customer?
          DocumentPreference
            .where(broker_customer: contact.companyable, contact: contacts)
            .update_all(broker_customer_id: contact.companyable_id)
        end

        contacts.find_each(&:destroy!)
        next
      end

      if user.present?
        next unless user.contact == contact

        if contact.customer?
          DocumentPreference
            .where(broker_customer: contact.companyable, contact: contacts)
            .update_all(broker_customer_id: contact.companyable_id)
        end

        contacts.find_each(&:destroy!)
        next
      end

      attributes = {}
      %i[first_name last_name email job_title label mobile_phone work_phone].each do |attribute|
        attributes[attribute] = [contact.public_send(attribute), contacts.pluck(attribute)].flatten.compact_blank.first
      end

      if contact.customer?
        DocumentPreference
          .where(broker_customer: contact.companyable, contact: contacts)
          .update_all(broker_customer_id: contact.companyable_id)
      end

      contacts.find_each(&:destroy!)
      contact.update!(attributes)
    end
  end

  def down; end
end
