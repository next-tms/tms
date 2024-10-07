require 'rails_helper'

RSpec.describe(ApplicationController) do
  describe '.authorization_targets' do
    it { expect(described_class.authorization_targets).to(include(authorizable: :current_user, user: :current_user)) }
  end
end
