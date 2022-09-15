# frozen_string_literal: true

module BrokerCarrier::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    def create_quickbooks_vendor
      return nil unless broker.intuit_account&.connected?

      return update_quickbooks_vendor unless quickbooks_vendor.blank?

      result = QuickbooksApiClient::Vendors.new(broker:).create(self)
      return @quickbooks_vendor = nil if result.blank?

      update_columns(quickbooks_vendor_id: result.id)
      @quickbooks_vendor = result
    end

    def update_quickbooks_vendor
      return nil unless broker.intuit_account&.connected?

      return create_quickbooks_vendor if quickbooks_vendor.blank?

      result = QuickbooksApiClient::Vendors.new(broker:).update(self)
      return @quickbooks_vendor = nil if result.blank?

      @quickbooks_vendor = result
    end

    def quickbooks_vendor
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_vendor unless @quickbooks_vendor.blank?

      result = nil

      result = QuickbooksApiClient::Vendors.new(broker:).find(quickbooks_vendor_id) unless quickbooks_vendor_id.blank?
      return @quickbooks_vendor = result unless result.blank?

      result = QuickbooksApiClient::Vendors.new(broker:).find_by_name(carrier.name)
      return nil if result.blank?

      update_columns(quickbooks_vendor_id: result.id)
      @quickbooks_vendor = result
    end

    def to_quickbooks_vendor
      Quickbooks::Model::Vendor.new(
        billing_address: check_mailing_address&.to_quickbooks_physical_address,
        company_name: carrier.name,
        display_name: carrier.name
      )
    end
  end
end
