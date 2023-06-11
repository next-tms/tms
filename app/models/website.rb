# frozen_string_literal: true

# @deprecated Moved to Setting
class Website < ApplicationRecord
  after_save :update_manifest, if: -> { saved_change_to_manifest? }

  belongs_to :broker

  validates :domain, :footer_url, :manifest_url, :sign_out_url, presence: true
  validates :domain, uniqueness: true

  def homepage_domain
    @homepage_domain ||=
      if homepage.blank?
        @website.domain
      else
        uri = URI.parse(homepage)
        PublicSuffix.parse(uri.host).domain
      end
  end

  def update_manifest
    response = HTTParty.get(manifest_url)
    return false unless response.code == 200

    begin
      json = JSON.parse(response.body)
    rescue StandardError
      return false
    end

    update(manifest: json)
  end
end
