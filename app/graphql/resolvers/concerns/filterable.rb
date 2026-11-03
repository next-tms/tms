module Resolvers
  module Concerns
    module Filterable
      extend ActiveSupport::Concern

      included do
        argument :page, Integer, default_value: 1, required: true, validates: { numericality: { greater_than: 0 } }
        argument :page_size, Integer, default_value: DEFAULT_PAGE_SIZE, required: true
        argument :sort, [String], required: false

        complexity ->(_context, arguments, child_complexity) { page_limit(arguments[:page_size]) * child_complexity }
      end

      class_methods do
        def page_limit(page_size) = page_size.clamp(1, MAX_PAGE_SIZE)
      end

      DEFAULT_PAGE_SIZE = 20
      MAX_PAGE_SIZE = 100

      def resolve(page:, page_size:, filter: nil, sort: nil)
        scope = authorized_scope(scoped_context)
        scope = apply_filter(scope, normalize_filter(filter)) if filter.present?
        scope = sorted_scope(scope, sort) if sort.present?

        Resolvers::Collection.new(scope, page:, page_size: self.class.page_limit(page_size))
      end

      private

      def aliased_key(key)
        name = key.to_s
        attribute, replacement = ransack_aliases.find { |original, _replacement| name == original || name.start_with?("#{original}_") }

        attribute ? :"#{replacement}#{name.delete_prefix(attribute)}" : key
      end

      def apply_filter(scope, filter)
        or_conditions = filter.delete(:or)

        scope = scope.ransack(filter, auth_object:).result if filter.present?
        return scope if or_conditions.blank?

        matching_ids = or_conditions.map { |condition| apply_filter(scope.klass.where(nil), condition).select(:id) }

        scope.where(id: matching_ids.map { |ids| scope.klass.where(id: ids) }.reduce(:or).select(:id))
      end

      def auth_object = context[:authorizable]
      def default_scope = self.class::MODEL.all

      def normalize_filter(filter)
        hash = filter.to_h.transform_keys { |key| aliased_key(key.to_s.underscore.to_sym) }
        hash = hash.reject { |_key, value| value.nil? || value.try(:empty?) }
        or_conditions = Array(hash.delete(:or)).filter_map { |condition| normalize_filter(condition).presence }

        or_conditions.any? ? hash.merge(or: or_conditions) : hash
      end

      def ransack_aliases = @ransack_aliases ||= self.class::MODEL.ransack_aliases(auth_object)

      def scoped_context
        return default_scope if object.blank?

        model_name = self.class::MODEL.model_name

        object.try(model_name.element.to_sym) || object.try(model_name.collection.to_sym) || default_scope
      end

      def sorted_scope(scope, sort)
        ransack_sorts = sort.map do |sort_field|
          field, direction = sort_field.split(':')

          "#{aliased_key(field)} #{direction&.downcase == 'desc' ? 'desc' : 'asc'}"
        end

        scope.ransack({ s: ransack_sorts }, auth_object:).result
      end
    end
  end
end
