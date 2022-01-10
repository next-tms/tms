# frozen_string_literal: true

class FetchWebsiteManifestJob < ApplicationJob
  def perform(website_id)
    Website.find(website_id).update_manifest
  end
end
