module TransponderService
  module Input
    class Contact < Base
      VALID_RECORD_CLASSES = [ ::Contact, ::Setting, ::Shipment, ::User ]
      VALID_ATTRIBUTE_PREFIXES = %i[shipper receiver]

      attr_reader :object, :attribute_prefix

      def initialize(object, attribute_prefix: nil)
        if VALID_RECORD_CLASSES.exclude?(object.class)
          raise ArgumentError, "object must be one of #{VALID_RECORD_CLASSES}.join(', ')}"
        elsif object.is_a?(::User) && !object.broker?
          raise ArgumentError, 'user must be a broker'
        end

        if object.is_a?(::Shipment) && VALID_ATTRIBUTE_PREFIXES.exclude?(attribute_prefix)
          raise ArgumentError, "attribute_prefix must be one of: #{VALID_ATTRIBUTE_PREFIXES.join(", ")}"
        else
          @attribute_prefix = attribute_prefix
        end

        super(object)
      end

      def build
        send("build_from_#{object.class.to_s.underscore}")
      end

      private

      def build_from_setting
        {
          company_name: Setting.value!(:name),
          email: Setting.customer_service_email!,
          name: Setting.value!(:name),
          phone: Setting.phone!
        }.compact
      end

      def build_from_contact(contact = nil)
        contact ||= object

        {
          company_name: contact.companyable&.name || Setting.value(:name),
          email: contact.email,
          name: contact.full_name,
          phone: contact.work_phone.presence || contact.mobile_phone
        }.compact
      end

      def build_from_shipment
        if attribute_prefix == :shipper
          return build_from_user(object.dispatcher)
                 .merge({ company_name: object.shipper_name.presence })
                 .compact
        end

        {
          company_name: object.receiver_name.presence,
          email: object.receiver_contact_email.presence,
          name: object.receiver_contact_name.presence,
          phone: object.receiver_contact_phone.presence
        }.compact
      end

      def build_from_user(user = nil)
        user ||= object

        build_from_setting.merge(build_from_contact(user.contact)).compact
      end
    end
  end
end
