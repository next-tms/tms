class SkillsController < ActionController::API
  CACHE_FOR = 1.hour

  def show = expires_in(CACHE_FOR, public: true)
end
