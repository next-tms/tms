class MarkMissedPickupRequestsJob < ApplicationJob
  def perform = PickupRequest.missed.find_each(&:miss!)
end
