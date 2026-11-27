require 'rails_helper'

RSpec.describe(AccessorialPolicy) do
  let!(:accessorial) { create(:accessorial, code: 'WKND') }
  let!(:broker_only) { create(:accessorial, broker_only: true, code: 'COMM') }
  let(:broker_customer) { create(:broker_customer) }
  let!(:customer_accessorial) { create(:accessorial, broker_customer:, code: 'CURB') }
  let!(:other_customer_accessorial) { create(:accessorial, broker_customer: create(:broker_customer), code: 'THRD') }
  let(:policy) { described_class.new(accessorial, authorizable:) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Accessorial.all, type: :active_record_relation) }

    context 'when authorizable.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(contain_exactly(accessorial, broker_only, customer_accessorial, other_customer_accessorial)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:carrier_user) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user, companyable: broker_customer) }

      it { is_expected.to(contain_exactly(accessorial, customer_accessorial)) }
    end
  end
end
