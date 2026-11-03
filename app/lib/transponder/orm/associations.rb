module Transponder
  module ORM
    module Associations
      extend ActiveSupport::Concern

      class_methods do
        def belongs_to_transponder(name, foreign_key:, class_name: name.to_s.camelize, optional: false)
          orm_class = "Transponder::ORM::#{class_name}".constantize

          define_method(name) do
            id = public_send(foreign_key)
            orm_class.find_or_initialize_by(orm_class.primary_key => id) if id.present?
          end

          define_method(:"#{name}=") { |orm_object| public_send(:"#{foreign_key}=", orm_object&.id) }

          validates foreign_key, presence: true unless optional

          # Only changed codes must still exist in Transponder, so records that store a removed code stay valid
          validate(if: :"will_save_change_to_#{foreign_key}?") do
            id = public_send(foreign_key)
            errors.add(name, :invalid) if id.present? && orm_class.find_by(orm_class.primary_key => id).nil?
          end
        end
      end
    end
  end
end
