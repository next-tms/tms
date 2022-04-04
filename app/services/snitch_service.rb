# frozen_string_literal: true

class SnitchService
  def self.snitch(object, messages)
    object_attributes = object.inspect
    object_name = object.class.name

    SnitchMailer.snitch(object_name, object_attributes, messages).deliver_later
  end
end
