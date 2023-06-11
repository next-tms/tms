# frozen_string_literal: true

module API
  class ApplicationController < ActionController::API
    before_action :authenticate_request

    attr_reader :current_api_user

    private

    def authenticate_request
      @current_user = AuthorizeAPIRequest.call(request.headers).result
      render(json: {  error: 'Unauthorized' }, status: :unauthorized) unless @current_user
    end
  end
end
