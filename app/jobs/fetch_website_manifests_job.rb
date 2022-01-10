# frozen_string_literal: true

class FetchWebsiteManifestsJob < ApplicationJob
  def perform
    Website.where.not(manifest_url: [nil, '']).pluck(:id).each do |website_id|
      FetchWebsiteManifest.perform_later(website_id)
    end
  end
end
