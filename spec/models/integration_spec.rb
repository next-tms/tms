require 'rails_helper'

RSpec.describe Integration do
  subject(:record) { build(:integration) }

  describe 'only one connected accounting integration' do
    let!(:other_record) { create(:integration) }

    it { is_expected.not_to be_valid }
    it { expect(record.tap(&:valid?).errors[:base]).to include('another accounting integration is already connected') }
  end
end
