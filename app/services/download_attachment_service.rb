# frozen_string_literal: true

class DownloadAttachmentService
  class << self
    def call(attachment)
      Tempfile.open([Time.current.to_i.to_s, ".#{attachment.filename.extension}"]) do |f| 
        f.binmode

        attachment.download { |chunk| f.write(chunk) }
        f.rewind
        
        f
      end
    end
  end
end
