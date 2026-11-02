module DSDC
  class << self
    def boolean(value) = ActiveModel::Type::Boolean.new.cast(value.is_a?(String) ? value.downcase : value)
  end
end
