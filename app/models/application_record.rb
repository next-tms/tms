class ApplicationRecord < ActiveRecord::Base
  include Ransackable
  include ORM::Associations

  class << self
    # @note For grouped_collection_select in forms
    def human_name
      model_name.human
    end
  end

  self.abstract_class = true

  delegate :human_attribute_name, to: :class

  def to_sgid_s
    to_sgid.to_s
  end
end
