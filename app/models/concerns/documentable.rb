# frozen_string_literal: true

module Documentable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier

  included do
    attr_accessor :changed_associations

    after_commit :documentable!

    before_save :set_changed_associations
  end

  def broadcast_new_document_generated(document_type)
    broadcast_namespaces(document_type).each do |namespace|
      broadcast_replace_to(
        self,
        :documents,
        target: broadcast_target(document_type, namespace),
        html: ApplicationController.render(
          partial: "#{namespace}/#{self.class.name.snakecase.pluralize}/documents/#{document_type}",
          locals: {
            self.class.name.snakecase.to_sym => self,
            this_dom_id: dom_id(self)
          },
        ).html_safe,
      )
    end
  end

  def broadcast_outdated_document(document_type)
    broadcast_namespaces(document_type).each do |namespace|
      target = broadcast_target(document_type, namespace)

      broadcast_replace_to(
        self,
        :documents,
        target:,
        html: "<tr id=\"#{target}\"></tr>".html_safe,
      )
    end
  end

  def broadcast_namespaces(document_type)
    return %i[broker customer] unless %i[broker_dispatch_sheet broker_carrier_quote].include?(document_type)

    %i[broker]
  end

  def broadcast_target(document_type, namespace)
    "#{namespace}_#{dom_id(self)}_#{document_type}"
  end

  def documentable?
    true
  end

  def documentable!
    DocumentableService.call(self)
  end

  private

  def set_changed_associations
    self.changed_associations = {}

    self.class.reflect_on_all_associations.each do |association|
      records = public_send(association.name)
      next if records.blank?

      if association.collection?
        next unless records.any? do |record|
                      record.new_record? || record.changes.any? || record.marked_for_destruction?
                    end

        changed_associations[association.name] = true
        next
      end

      next unless records.new_record? || records.changes.any? || records.marked_for_destruction?

      changed_associations[association.name] = true
    end
  end
end
