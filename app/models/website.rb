# frozen_string_literal: true

class Website < ApplicationRecord
  belongs_to :broker

  validates_presence_of :domain, :footer_url, :manifest_url, :sign_out_url
  validates_uniqueness_of :domain

  def homepage_domain
    @homepage_domain ||=
      if homepage.blank?
        @website.domain
      else
        uri = URI.parse(homepage)
        PublicSuffix.parse(uri.host).domain
      end
  end

  def manifest
    Rails.cache.fetch(manifest_url, expires_in: 3.hours) do
      response = HTTParty.get(manifest_url)
      break unless response.code == 200

      begin
        JSON.parse(response.body)
      rescue StandardError
        break
      end
    end
  end
end
