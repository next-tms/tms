require 'rails_helper'

RSpec.describe(WelcomeController) do
  describe '#after_sign_in_path' do
    before { allow(controller).to(receive(:current_user).and_return(user)) }

    context 'when current_user.broker?' do
      let(:user) { build(:broker_user) }

      it { expect(controller.after_sign_in_path).to(eq(yours_broker_problems_path)) }
    end

    context 'when current_user.carrier?' do
      let(:user) { build(:carrier_user) }

      it { expect(controller.after_sign_in_path).to(eq(carrier_root_path)) }
    end

    context 'when current_user.customer?' do
      let(:user) { build(:customer_user) }

      it { expect(controller.after_sign_in_path).to(eq(customer_shipments_path)) }
    end
  end
end
