# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute role_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_user_roles_on_role_id  (role_id)
#  index_user_roles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
# @deprecated Removed, only exists for historical reasons
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
