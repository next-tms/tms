# frozen_string_literal: true

module Bank::QuickbooksSyncable
  extend ActiveSupport::Concern

  included do
    after_commit :push_to_quickbooks

    def create_quickbooks_account
      return nil unless broker.intuit_account&.connected?

      return update_quickbooks_account unless quickbooks_account.blank?

      result = QuickbooksAPIClient::Accounts.new(broker:).create(self)
      return @quickbooks_account = nil if result.blank?

      update_columns(quickbooks_account_id: result.id)
      @quickbooks_account = result
    end

    def update_quickbooks_account
      return nil unless broker.intuit_account&.connected?

      return create_quickbooks_account if quickbooks_account.blank?

      result = QuickbooksAPIClient::Accounts.new(broker:).update(self)
      return @quickbooks_account = nil if result.blank?

      @quickbooks_account = result
    end

    def quickbooks_account
      return nil unless broker.intuit_account&.connected?
      return @quickbooks_account unless @quickbooks_account.blank?

      result = nil

      unless quickbooks_account_id.blank?
        result = QuickbooksAPIClient::Accounts.new(broker:).find(quickbooks_account_id)
      end
      return @quickbooks_account = result unless result.blank?

      result = QuickbooksAPIClient::Accounts.new(broker:).find_by_name(quickbooks_account_name)
      return nil if result.blank?

      update_columns(quickbooks_account_id: result.id)
      @quickbooks_account = result
    end

    def quickbooks_account_name
      parts = [ name ]
      parts << account_number[..3] unless account_number.blank?

      parts.join(' ').gsub(':', ' -').gsub('"', '').squish[..99]
    end

    private

    def push_to_quickbooks
      PushBankToQuickbooksJob.perform_later(self) if broker.intuit_account.present?
    end
  end
end
