# frozen_string_literal: true

# == Schema Information
#
# Table name: websites
#
# @!attribute id
#   @return []
# @!attribute copyright_holder
#   @return [String]
# @!attribute css
#   @return [String]
# @!attribute desc
#   @return [String]
# @!attribute domain
#   @return [String]
# @!attribute footer_url
#   @return [String]
# @!attribute homepage
#   @return [String]
# @!attribute logo_image_data
#   @return [String]
# @!attribute manifest
#   @return [Hash]
# @!attribute manifest_url
#   @return [String]
# @!attribute modal_url
#   @return [String]
# @!attribute sign_out_url
#   @return [String]
# @!attribute slogan
#   @return [String]
# @!attribute v_card_logo_base64
#   @return [String]
# @!attribute broker_id
#   @return []
#
# Indexes
#
#  index_websites_on_broker_id  (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#
class Website < ApplicationRecord
  after_save :update_manifest, if: -> { saved_change_to_manifest? }

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
