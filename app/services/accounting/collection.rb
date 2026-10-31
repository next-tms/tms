module Accounting
  class Collection
    include Enumerable

    attr_reader :filter, :orm_class, :page, :page_size, :sort

    def initialize(orm_class, filter: {}, page: nil, page_size: nil, sort: nil)
      @filter = filter
      @orm_class = orm_class
      @page = page
      @page_size = page_size
      @sort = sort
    end

    def each(&) = to_a.each(&)
    delegate :find, to: :connection
    def find_by(**conditions) = connection.find_by(conditions)
    def find_by!(**conditions) = find_by(**conditions) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{orm_class}")
    delegate :first, to: :to_a
    def limit(page_size) = with(page: page || 1, page_size:)
    def order(**sort) = with(sort:)
    def to_a = @to_a ||= connection.all(filter:, page:, page_size:, sort:)
    def where(**conditions) = with(filter: filter.merge(conditions))

    private

    def connection = orm_class.connection
    def with(**) = self.class.new(orm_class, filter:, page:, page_size:, sort:, **)
  end
end
