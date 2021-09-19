# frozen_string_literal

class AddContactToUsers < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :contact, null: true, foreign_key: true
  end
end
