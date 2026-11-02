class GraphiQLController < ApplicationController
  before_action :authenticate_user!

  layout false

  def show; end
end
