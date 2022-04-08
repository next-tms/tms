# frozen_string_literal: true

class CreateProblemsJob < ApplicationJob
  def perform
    ProblemService.create_problems
  end
end
