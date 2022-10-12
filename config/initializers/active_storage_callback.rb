### DEVELOPER NOTE:
# Currently ActiveStorage doesn't offer a callback feature. And monkey patching this class doesn't also work
# So the only way to have a callback for ActiveStorage::Attachment, is to copy the class from the source code,
# and from there, Inject our custom callback
# Source Code Ref: https://github.com/rails/rails/blob/fc5dd0b85189811062c85520fd70de8389b55aeb/activestorage/app/models/active_storage/attachment.rb#L20

require "active_support/core_ext/module/delegation"

# Attachments associate records with blobs. Usually that's a one record-many blobs relationship,
# but it is possible to associate many different records with the same blob. If you're doing that,
# you'll want to declare with <tt>has_one/many_attached :thingy, dependent: false</tt>, so that destroying
# any one record won't destroy the blob as well. (Then you'll need to do your own garbage collecting, though).
class ActiveStorage::Attachment < ActiveRecord::Base
  self.table_name = "active_storage_attachments"

  belongs_to :record, polymorphic: true, touch: true
  belongs_to :blob, class_name: "ActiveStorage::Blob"

  delegate_missing_to :blob

  after_create_commit :analyze_blob_later, :identify_blob, :resolve_problems_related_to_this_attachment

  # Synchronously purges the blob (deletes it from the configured service) and destroys the attachment.
  def purge
    blob.purge
    destroy
  end

  # Destroys the attachment and asynchronously purges the blob (deletes it from the configured service).
  def purge_later
    blob.purge_later
    destroy
  end

  private

  def identify_blob
    blob.identify
  end

  def analyze_blob_later
    blob.analyze_later unless blob.analyzed?
  end

  # This is our custom callback
  def resolve_problems_related_to_this_attachment
    return unless self.record_type == 'Shipment'

    shipment = self.record
    attachment_name = self.name

    problem_code = "missing_#{attachment_name}"
    problem_type = ProblemType.find_by(code: problem_code)
    return unless problem_type

    problems = shipment.problems.unresolved.where(problem_type: problem_type)
    return if problems.blank?

    problems.update_all(resolved_at: Time.now)
  end
end
