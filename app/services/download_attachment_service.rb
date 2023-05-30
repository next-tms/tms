# frozen_string_literal: true

class DownloadAttachmentService
  class << self
    def call(attachment)
      binary = attachment.download
      filename = "#{Time.current.to_i}_#{rand(1..1000)}.#{attachment.filename.extension}"
      path = Rails.root.join('tmp', filename)

      File.binwrite(path, binary)
      File.open(path)
    end
  end
end
