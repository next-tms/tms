class Problem::ResolveJob < ApplicationJob
  def perform(problem) = problem.resolve
end
