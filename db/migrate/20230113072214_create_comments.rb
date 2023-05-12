# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table(:comments) do |t|
      t.references(:contact, null: false, foreign_key: true)
      t.references(:discussion_topic, null: false, foreign_key: true)

      t.text(:body)

      t.timestamps
    end
  end
end
