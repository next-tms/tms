require 'rails_helper'

RSpec.describe(ProblematicService::Rule) do
  describe 'class methods' do
    subject { described_class }

    it { is_expected.to(respond_to(:all)) }
    it { is_expected.to(respond_to(:code)) }
    it { is_expected.to(respond_to(:model)) }
  end

  describe '#assign' do
    subject(:assigned_to) { ProblematicService::Rule::Shipment::MissingChargesConfirmed.new(nil).with(shipment).send(:assign) }

    let(:shipment) { build(:shipment).tap { |record| record.dispatcher = nil } }
    let!(:staff_user) { create(:broker_user).tap { |user| user.add_role(:accounts_receivable) } }

    before { create(:customer_user).tap { |user| user.add_role(:accounts_receivable) } }

    it { is_expected.to(eq(staff_user)) }
  end
end
