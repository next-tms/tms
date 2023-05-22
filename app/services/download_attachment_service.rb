# frozen_string_literal: true

class DownloadAttachmentService
  class << self
    def call(attachment)
      binary = attachment.download
      path = Rails.root.join('tmp', "{Time.current.to_i}.#{attachment.filename.extension}")

      File.binwrite(path, binary)
    end
  end
end
