module UnknownIncludes
  # Returns "Model#association" for each `includes` value that the model does not define.
  def unknown_includes(model, values)
    case values
    when Array then values.flat_map { |value| unknown_includes(model, value) }
    when Hash then values.flat_map { |name, nested| unknown_includes(model, name) + nested_unknown_includes(model, name, nested) }
    else model.reflect_on_association(values) ? [] : ["#{model.name}##{values}"]
    end
  end

  private

  def nested_unknown_includes(model, name, nested)
    reflection = model.reflect_on_association(name)
    return [] if reflection.nil? || reflection.polymorphic?

    unknown_includes(reflection.klass, nested)
  end
end

RSpec.configure do |config|
  config.include(UnknownIncludes)
end
