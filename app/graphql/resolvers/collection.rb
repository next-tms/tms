module Resolvers
  class Collection
    attr_reader :page, :page_size, :scope

    def initialize(scope, page:, page_size:)
      @page = page
      @page_size = page_size
      @scope = scope
    end

    def items = @items ||= scope.order(:id).offset(page == 1 ? 0 : pagy.offset).limit(page_size)
    def pagy = @pagy ||= Pagy.new(count: scope.count, limit: page_size, page:)
    def pages = pagy.last
    def total_items = pagy.count
    def updated_at = scope.maximum(:updated_at)
    def version = scope.cache_version
  end
end
