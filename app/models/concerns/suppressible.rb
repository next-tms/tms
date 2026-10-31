module Suppressible
  extend ActiveSupport::Concern

  included do
    validate :suppressible!

    def suppressed_by_problematic
      raise NotImplementedError
    end

    private

    def suppressible!
      return unless suppressions.any?

      suppressions.find_each { |suppression| errors.add(:base, suppression.describe) }
    end

    def suppressions
      @suppressions ||= Suppression.where(problematic: suppressed_by_problematic, suppressible_type: self.class.name)
    end
  end
end
