module AuthorizedAttributablePolicy
  def self.included(base)
    base.class_eval do
      self::BROKER_ATTRIBUTES.each do |attribute|
        define_method("#{attribute}_attribute?") do
          broker?
        end
      end

      self::CUSTOMER_ATTRIBUTES.each do |attribute|
        define_method("#{attribute}_attribute?") do
          customer? || broker?
        end
      end
    end
  end
end
