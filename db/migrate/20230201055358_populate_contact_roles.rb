# frozen_string_literal: true

class PopulateContactRoles < ActiveRecord::Migration[7.0]
  def up
    say('populate(:contact_roles)')
    User.includes(user_roles: :role).find_each do |user|
      contact_id = user.contact.id

      Role
      .where(id: user.user_roles.pluck(:role_id))
      .pluck(:name)
      .select { |name| ContactRole.roles.keys.include?(name) }
      .map { |role| ContactRole.create(role:, contact_id:) }
    end
  end

  def down; end
end
