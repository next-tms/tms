class Problem::ResolveManyJob < ApplicationJob
  def perform = Problem.unresolved.select(&:resolve?).each { |problem| Problem::ResolveJob.perform_later(problem) }
end
