module AuthorizedAttributablePolicy
  BROKER_METHODS = [].freeze
  CUSTOMER_METHODS = [].freeze

  def self.included(base)
    base.class_eval do
      (self::BROKER_ATTRIBUTES + self::BROKER_METHODS).each do |attribute|
        define_method("#{attribute}_attribute?") do
          broker?
        end
      end

      (self::CUSTOMER_ATTRIBUTES + self::CUSTOMER_METHODS).each do |attribute|
        define_method("#{attribute}_attribute?") do
          customer? || broker?
        end
      end
    end
  end
end
