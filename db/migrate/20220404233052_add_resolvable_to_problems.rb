# frozen_string_literal: true

class AddResolvableToProblems < ActiveRecord::Migration[7.0]
  def change
    add_reference :problems, :resolvable, polymorphic: true, null: true
  end
end
