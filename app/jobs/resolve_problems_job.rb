# frozen_string_literal: true

class ResolveProblemsJob < ApplicationJob
  def perform
    ProblemService.resolve_problems
  end
end
