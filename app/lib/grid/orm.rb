module Grid
  module ORM
    class << self
      def version
        @version ||= begin
          files = Rails.root.glob('app/lib/{graphql_client/,}grid/**/*.rb').sort
          files << Rails.root.join('schemas/grid.json')

          data = files.map { |file| Digest::SHA256.file(file).hexdigest }.join

          Digest::SHA256.hexdigest(data)
        end
      end
    end
  end
end
