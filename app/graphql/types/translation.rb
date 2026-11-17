module Types
  module Translation
    class << self
      def call(*keys)
        translation = I18n.t(keys.join('.'), default: nil, scope: :graphql)

        translation && I18n.interpolate(translation, model_names(translation))
      end

      def model_name(key) = key.classify.constantize.model_name.human(count: key == key.pluralize ? :other : 1)
      def model_names(translation) = translation.scan(/%\{(\w+)\}/).flatten.uniq.to_h { |key| [key.to_sym, model_name(key)] }
    end
  end
end
