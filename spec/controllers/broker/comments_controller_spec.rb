require 'rails_helper'

RSpec.describe(Broker::CommentsController) do
  subject { response }

  let(:body) { 'Called the shipper' }
  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:discussion_topic) { problem.discussion_topic }
  let(:params) { { comment: { body: }, discussion_id: discussion_topic.discussion_id, discussion_topic_id: discussion_topic.id } }
  let(:problem) { create(:problem) }

  before { sign_in(current_user) }

  describe 'POST #create' do
    render_views

    context 'when requested as a Turbo Stream' do
      before { post(:create, params:, format: :turbo_stream) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(discussion_topic.comments.last).to(have_attributes(body:, contact: current_user.contact)) }
      it { expect(response.body).to(include(%(action="prepend" target="#{ActionView::RecordIdentifier.dom_id(discussion_topic, :comments)}"))) }
    end

    context 'when requested as HTML' do
      before { post(:create, params:) }

      it { is_expected.to(redirect_to(root_path)) }
      it { expect(discussion_topic.comments.last).to(have_attributes(body:)) }
    end

    context 'when the comment is invalid' do
      let(:body) { '' }

      before { post(:create, params:, format: :turbo_stream) }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
      it { expect(discussion_topic.comments).to(be_empty) }
      it { expect(response.body).to(include(%(action="replace" target="#{ActionView::RecordIdentifier.dom_id(discussion_topic, :new_comment)}"))) }
      it { expect(response.body).to(include('invalid-feedback')) }
    end
  end
end
