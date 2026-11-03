module Sources
  class Association < GraphQL::Dataloader::Source
    def initialize(model_class, association_name)
      super()

      @association_name = association_name

      return if model_class.reflect_on_association(association_name)

      raise(ArgumentError, "Association '#{association_name}' not found on #{model_class}")
    end

    def fetch(records)
      ActiveRecord::Associations::Preloader.new(associations: @association_name, records:).call

      records.map { |record| record.public_send(@association_name) }
    end
  end
end
