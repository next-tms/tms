class UpgradeUsersDeviseInvitations < ActiveRecord::Migration[8.1]
  class Invitation < ActiveRecord::Base
    self.table_name = 'devise_invitations'
  end

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  def up
    create_table :devise_invitations do |t|
      t.string :invitation_token
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.datetime :superseded_at
      t.string :superseded_reason
      t.datetime :revoked_at
      t.datetime :resource_created_at
      t.json :invite_key, null: false, default: {}
      t.string :invite_key_digest, null: false
      t.references :invitable, polymorphic: true
      t.references :invited_by, polymorphic: true
      t.timestamps
    end
    add_index :devise_invitations, :invitation_token, unique: true
    add_index :devise_invitations, %i[invitable_type invite_key_digest], name: 'index_devise_invitations_on_type_and_invite_key'

    Invitation.reset_column_information
    User.reset_column_information

    User.where.not(invitation_created_at: nil).or(User.where.not(invitation_accepted_at: nil)).find_each do |user|
      created_at = user.invitation_created_at || user.invitation_accepted_at

      Invitation.create!(
        created_at:,
        invitable_id: user.id,
        invitable_type: 'User',
        invitation_accepted_at: user.invitation_accepted_at,
        invitation_created_at: user.invitation_created_at,
        invitation_sent_at: user.invitation_sent_at,
        invitation_token: user.invitation_token,
        invite_key: { 'email' => user.email },
        invite_key_digest: Digest::SHA256.hexdigest(['User', 'email', user.email.to_s].join("\0")),
        invited_by_id: user.invited_by_id,
        invited_by_type: user.invited_by_id && 'User',
        resource_created_at: created_at,
        updated_at: user.invitation_accepted_at || user.invitation_sent_at || created_at
      )
    end

    remove_column :users, :invitation_accepted_at, :datetime
    remove_column :users, :invitation_created_at, :datetime
    remove_column :users, :invitation_sent_at, :datetime
    remove_column :users, :invitation_token, :string
    remove_reference :users, :invited_by, foreign_key: { to_table: :users }
  end

  def down
    add_column :users, :invitation_accepted_at, :datetime, precision: nil
    add_column :users, :invitation_created_at, :datetime, precision: nil
    add_column :users, :invitation_sent_at, :datetime, precision: nil
    add_column :users, :invitation_token, :string
    add_index :users, :invitation_token, unique: true
    add_reference :users, :invited_by, foreign_key: { to_table: :users }

    User.reset_column_information

    Invitation.where(invitable_type: 'User').group_by(&:invitable_id).each do |user_id, invitations|
      latest = invitations.sort_by(&:created_at).reverse
      pending = latest.find { |candidate| [candidate.invitation_accepted_at, candidate.revoked_at, candidate.superseded_at].none? }
      invitation = pending || latest.first

      User.where(id: user_id).update_all(
        invitation_accepted_at: invitation.invitation_accepted_at,
        invitation_created_at: invitation.invitation_created_at,
        invitation_sent_at: invitation.invitation_sent_at,
        invitation_token: invitation.invitation_token,
        invited_by_id: invitation.invited_by_type == 'User' ? invitation.invited_by_id : nil
      )
    end

    drop_table :devise_invitations
  end
end
