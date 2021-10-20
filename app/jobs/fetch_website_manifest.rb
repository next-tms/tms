# frozen_string_literal: true

class FetchWebsiteManifest < ApplicationJob
  def perform(website_id)
    Website.find(website_id).update_manifest
  end
end
