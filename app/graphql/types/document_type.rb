module Types
  class DocumentType < Types::BaseObject
    URL_EXPIRES_IN = 5.minutes

    description 'GraphQL Object for Documents'

    field :byte_size, Integer, null: false
    field :content_type, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :filename, String, null: false
    field :id, ID, null: false
    field :kind, Types::DocumentKindEnum, method: :name, null: false
    field :url, String, null: false

    def filename = object.filename.to_s
    def url = Rails.application.routes.url_helpers.rails_blob_url(object, expires_in: URL_EXPIRES_IN, **url_options)

    private

    def protocol = Rails.application.config.force_ssl ? 'https' : 'http'
    def url_options = Rails.application.config.action_mailer.default_url_options.merge(protocol:)
  end
end
