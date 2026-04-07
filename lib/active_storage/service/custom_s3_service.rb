require 'active_storage/service/s3_service'
require 'uri'

class ActiveStorage::Service::CustomS3Service < ActiveStorage::Service::S3Service
  private

  def public_url(key, **)
    return object_for(key).public_url unless Rails.env.production?

    uri = URI.parse(object_for(key).public_url)
    uri.host = ENV.fetch('AWS_CDN_HOST')
    uri.to_s
  end
end
