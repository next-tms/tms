module ORM
  class Collection
    include Enumerable

    attr_reader :orm_class

    delegate :[], :each, :empty?, :last, :size, :to_ary, to: :to_a

    def initialize(orm_class, orm_objects)
      raise ArgumentError, 'orm_class must be descended from ORM::Base' unless orm_class < Base

      @orm_class = orm_class
      @orm_objects = orm_objects
    end

    def find(id) = index[id] || raise(not_found(orm_class.primary_key => id))
    def find_by(**conditions) = where(**conditions).first
    def find_by!(**conditions) = find_by(**conditions) || raise(not_found(**conditions))
    def inspect = "#<#{self.class.name} orm_class=#{orm_class} size=#{size}>"
    def order(attribute) = self.class.new(orm_class, sort_by(&attribute))
    def pluck(attribute) = map(&attribute)
    def to_a = @orm_objects

    def where(**conditions)
      return self if conditions.blank?

      primary_key = orm_class.primary_key
      candidates = conditions.key?(primary_key) ? Array.wrap(conditions[primary_key]).filter_map { |id| index[id] } : to_a

      orm_objects = candidates.select do |orm_object|
        conditions.except(primary_key).all? do |attribute, value|
          attribute_value = orm_object.public_send(attribute)

          value.is_a?(Array) ? value.include?(attribute_value) : attribute_value == value
        end
      end

      self.class.new(orm_class, orm_objects)
    end

    private

    def index = @index ||= index_by(&:id)

    def not_found(**conditions) = ActiveRecord::RecordNotFound.new("Couldn't find #{orm_class} with #{conditions}", orm_class.name)
  end
end
