# frozen_string_literal: true

class DownloadAttachmentService
  class << self
    def call(attachment)
      File.write(Rails.root.join('tmp', Time.current.to_i.to_s, attachment.filename.extension))
    end
  end
end
