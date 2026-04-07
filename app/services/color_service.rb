class ColorService
  class << self
    def hex_to_rgb(value)
      value.match(/^#(..)(..)(..)$/).captures.map(&:hex).join(', ')
    end
  end
end
