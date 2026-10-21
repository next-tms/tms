class ReportPolicy < ApplicationPolicy
  def create? = index?
  def destroy? = manage?
  def edit? = manage?
  def index? = broker? && any_role?(:accounts_receivable, :dispatch, :sales_rep)
  def manage? = !record.preset? && view? && (admin? || record.created_by == authorizable)
  def new? = create?
  def show? = view?
  def update? = manage?
  def view? = index? && (record.preset? || record.broker == authorizable.companyable)
end
