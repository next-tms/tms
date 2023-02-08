# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Here mainly for grouped_collection_select in forms
  def self.human_name
    model_name.human
  end

  def to_sgid_s
    to_sgid.to_s
  end
end
