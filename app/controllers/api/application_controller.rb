# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_request

    before_action :set_website
    attr_reader :current_api_user

    private

    def authenticate_request
      @current_user = AuthorizeApiRequest.call(request.headers).result
      render json: {  error: 'Unauthorized' }, status: :unauthorized unless @current_user
    end

    # rubocop:disable Naming/MemoizedInstanceVariableName
    # TODO: Rename method name and memoized variable to current_website
    def set_website
      @website ||= Website.find_by_domain(request.host) || nil
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName
  end
end
