# frozen_string_literal: true

class Broker::ProblemsController < Broker::BrokerController
  before_action :set_problem, only: %i[edit show update]
  before_action :authenticate_user!

  def index
    @q = current_user.problems.includes(required_includes).ransack(params[:q])
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
      redirect_to [:broker, @problem]
    else
      render :edit
    end
  end

  def edit; end

  def update
    @problem.assign_attributes(problem_params)

    @problem.resolved_by = current_user if @problem.will_save_change_to_resolved_at? && !@problem.resolved_at.blank?

    if @problem.save
      redirect_to broker_problem_path(@problem)
    else
      flash[:error] = 'Unable to update exception'
      render :edit
    end
  end

  def resolved
    @q = current_user.eligible_problems.resolved.includes(required_includes).ransack(params[:q])
    @q.sorts = 'resolved_at desc' if @q.sorts.blank?

    @pagy, @problems = pagy(@q.result)
  end

  def show; end

  def unresolved
    @q = current_user.eligible_problems.unresolved.includes(required_includes).ransack(params[:q])
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
      :title
    )
  end

  def required_includes
    %i[problem_type resolvable]
  end
end
