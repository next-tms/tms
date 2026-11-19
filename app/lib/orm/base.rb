module ORM
  class Base
    class << self
      delegate :find, :find_by, :find_by!, :first, :last, :order, :pluck, :where, to: :all

      def all = raise(NotImplementedError, "#{name} must implement .all")
      def find_or_initialize_by(**attributes) = find_by(**attributes) || new(**attributes)
      def model_name = @model_name ||= ActiveModel::Name.new(self)
      def primary_key = raise(NotImplementedError, "#{name} must implement .primary_key")
      def reset = @all = nil
    end

    delegate :model_name, to: :class

    def ==(other) = other.is_a?(self.class) && other.id == id
    alias eql? ==

    def cache_key = "#{model_name.cache_key}/#{id}"
    def cache_key_with_version = "#{cache_key}-#{cache_version}"
    def cache_version = raise(NotImplementedError, "#{self.class.name} must implement #cache_version")
    def hash = [self.class, id].hash
    def id = public_send(self.class.primary_key)
    def inspect = "#<#{self.class.name} id=#{id}>"
    def persisted? = true
    def to_model = self
    def to_param = id
    def updated_at = nil
  end
end
