# frozen_string_literal: true

module Documentable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier

  included do
    after_save :documentable!
  end

  def broadcast_new_document_generated(document_type)
    broadcast_namespaces(document_type).each do |namespace|
      partial = "#{namespace}/#{self.class.name.snakecase.pluralize}/documents/#{document_type}"

      broadcast_replace_to(
        self,
        :documents,
        target: broadcast_target(document_type, namespace),
        html: ApplicationController.render(
          partial:,
          locals: {
            self.class.name.snakecase => self,
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

  def documentable!
    self.class::DOCUMENTABLE_TYPES.each { |document_type| DocumentableService.call!(self, document_type) }
  end
end
