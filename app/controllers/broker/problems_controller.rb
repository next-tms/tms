class Broker::ProblemsController < Broker::BrokerController
  before_action :set_problem, only: %i[edit show update]
  before_action :set_scoped_problems, only: %i[index resolved suppressive team yours]
  before_action :authenticate_user!

  def index
    @q = @scoped_problems.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at asc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  def new
    @problem = Problem.new
  end

  def create
    @problem.assign_attributes(problem_params)

    @problem.created_by = current_user

    if @problem.save
      redirect_to([ :broker, @problem ])
    else
      render(:edit)
    end
  end

  def edit; end

  def suppressive
    @q = @scoped_problems.unresolved.suppressive.includes(required_includes).ransack(
      params[:q],
      auth_object: current_user,
    )
    @q.sorts = 'created_at asc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  def update
    @problem.assign_attributes(problem_params)

    @problem.resolved_by = current_user if @problem.will_save_change_to_resolved_at? && @problem.resolved_at.present?

    if @problem.save
      redirect_to(broker_problem_path(@problem))
    else
      flash[:error] = 'Unable to update exception'
      render(:edit)
    end
  end

  def resolved
    @q = @scoped_problems.resolved.includes(required_includes + %i[resolved_by]).ransack(
      params[:q],
      auth_object: current_user,
    )
    @q.sorts = 'resolved_at desc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  def show; end

  def team
    @q = @scoped_problems.unresolved.includes(required_includes).ransack(params[:q], auth_object: current_user)
    @q.sorts = 'created_at asc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  def yours
    @q = @scoped_problems.unresolved.where(assigned_to: current_user).includes(required_includes).ransack(
      params[:q],
      auth_object: current_user,
    )
    @q.sorts = 'created_at asc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_problem
    @problem = Problem.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def problem_params
    params.require(:problem).permit(
      :id,
      :body,
      :resolved_at,
      :resolvable_id,
      :resolvable_type,
      :title,
    )
  end

  def required_includes
    %i[assigned_to resolvable]
  end

  def set_scoped_problems
    @scoped_problems = Problem.by_any_role(*current_user.roles)
  end
end
