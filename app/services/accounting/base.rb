module Accounting
  class Base
    include ActiveModel::Model

    class << self
      delegate :find, :find_by, :find_by!, :first, :sort_by, :where, to: :all

      def all = Collection.new(self)
      def connection = raise NotImplementedError
      def create(attributes = {}) = new(**attributes).tap(&:save)

      def attribute(name)
        define_method(name) { self[name] }
        define_method(:"#{name}=") { |value| @attributes[name] = value }
      end
    end

    attr_reader :id

    def initialize(id = nil, loaded: false, **attributes)
      @id = id
      @loaded = loaded
      @attributes = attributes
    end

    def ==(other) = other.instance_of?(self.class) && other.id == id

    def [](name)
      reload if !@attributes.key?(name) && persisted? && !loaded?

      @attributes[name]
    end

    def attributes = @attributes
    def destroy = self.class.connection.destroy(self)
    def loaded? = @loaded

    def order(*attributes)
      collection = all

      attributes.each { |attribute| collection = collection.sort_by(&attribute.to_proc) }

      collection
    end

    def persisted? = id.present?

    def reload
      replace(self.class.connection.find(id))
      self
    end

    def save
      replace(persisted? ? self.class.connection.update(self) : self.class.connection.create(self))
      self
    end

    private

    def replace(record)
      @attributes = record.attributes
      @id = record.id
      @loaded = true
    end
  end
end
