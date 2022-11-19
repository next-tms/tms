# frozen_string_literal: true

class ProblematicJob < ApplicationJob
  queue_as :low_priority

  def perform(ids, type:)
    type.constantize.where(id: ids).find_each(&:problematic!)
  end
end
