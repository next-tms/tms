class RatePolicy < ApplicationPolicy
  def view_charges? = broker? || customer?
  def view_costs? = broker?
end
