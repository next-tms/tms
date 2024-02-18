# frozen_string_literal: true

module DocumentableService
  class Base
    class << self
      def call(record)
        new(record).call
      end
    end

    attr_reader :document_type, :record

    def initialize(record)
      model = "::#{self.class.to_s.split("::")[-2]}".constantize

      raise ArgumentError, "record must be a #{model}" unless record.is_a?(model)
      raise ArgumentError, 'record must be #documentable?' unless record.try(:documentable?)

      document_type = self.class.to_s.demodulize.snakecase.to_sym

      raise "Unknown document_type \"#{document_type}\"" if model::DOCUMENTABLE_TYPES.exclude?(document_type)

      @document_type = document_type
      @record = record
    end

    def call
      record.skip_documentable_callback = true

      if missing_changes.any?
        destroy_document!
        return
      end

      return if matched_changes.empty?

      destroy_document!
      create_document!

      nil
    end

    private

    def check_associations
      raise NotImplementedError
    end

    def check_attributes
      raise NotImplementedError
    end

    def create_document!
      "DocumentableService::#{record.class}::Create#{document_type.to_s.camelcase}Job".constantize.perform_later(record)
    end

    def destroy_document!
      record.broadcast_outdated_document(document_type)

      document = record.public_send(document_type)
      return unless document.attached?

      document.purge
    end

    def matched_changes
      @matched_changes ||= if record.changed_associations.nil?
                             return []
                           else
                             [].tap do |builder|
                               ActiveRecord::Base.transaction(requires_new: true) do
                                 check_associations.each do |association|
                                   next if record.changed_associations.exclude?(association)

                                   builder << association
                                 end

                                 check_attributes.each do |attribute|
                                   next unless record.public_send("saved_change_to_#{attribute}?")

                                   builder << attribute
                                 end
                               end
                             end
                           end
    end

    def missing_changes
      @missing_changes ||= []
    end
  end
end
