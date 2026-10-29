class Broker::CommentsController < Broker::BrokerController
  before_action :set_discussion
  before_action :set_discussion_topic

  def create
    @comment = @discussion_topic.comments.new(comment_params.merge(contact: current_user.contact))

    respond_to do |format|
      if @comment.save
        format.html { redirect_back_or_to(root_path) }
        format.turbo_stream
      else
        format.turbo_stream { render(:create, status: :unprocessable_content) }
      end
    end
  end

  private

  def comment_params = params.expect(comment: [ :body ])
  def set_discussion = @discussion = Discussion.find_by!(id: params[:discussion_id])
  def set_discussion_topic = @discussion_topic = @discussion.discussion_topics.find_by!(id: params[:discussion_topic_id])
end
