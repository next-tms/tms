# frozen_string_literal: true

module Instigatable
  extend ActiveSupport::Concern

  included do
    after_save :update_suppressors

    has_many :suppressors, as: :instigator, dependent: :destroy
    has_many :suppressions, dependent: :destroy, through: :suppressors

    private

    def suppressor_mappings
      @suppressor_mappings ||= self.class::SUPPRESSOR_MAPPINGS
    end

    def update_suppressors
      suppressor_mappings.each_key do |key|
        suppressor_attributes = suppressor_mappings[key]
        suppressor_enabled = public_send(key)

        unless suppressor_enabled
          suppressors.where(suppressor_attributes).destroy_all
          next
        end

        existing_suppressors = suppressors.where(suppressor_attributes)

        if existing_suppressors.any?
          suppressors.where(suppressor_attributes).touch_all
          next
        end

        suppressors.create!(suppressor_attributes)
      end
    end
  end
end
