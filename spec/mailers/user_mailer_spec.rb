require 'rails_helper'

RSpec.describe(UserMailer) do
  describe('._helpers') do
    subject { described_class._helpers }

    it { is_expected.to(include(ApplicationHelper)) }
    it { is_expected.to(include(DateTimeHelper)) }
  end
end
