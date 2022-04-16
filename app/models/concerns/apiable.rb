# frozen_string_literal: true

module Apiable
  extend ActiveSupport::Concern

  included do
    # serialize :api_request
    # serialize :api_response
  end
end
