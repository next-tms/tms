module Transponder
  module ORM
    class << self
      def version
        @version ||= begin
          files = Rails.root.glob('app/lib/{graphql_client/,}transponder/**/*.rb').sort
          files << Rails.root.join('schemas/transponder.json')

          data = files.map { |file| Digest::SHA256.file(file).hexdigest }.join

          Digest::SHA256.hexdigest(data)
        end
      end
    end
  end
end
