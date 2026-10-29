module ProblematicService
  class Action
    class << self
      def call(problem) = new(problem).call
    end

    attr_reader :problem

    delegate :discussion_topic, to: :problem

    def initialize(problem)
      @problem = problem
    end

    def call = raise(NotImplementedError)
    def discussion_topic? = discussion_topic.present?
  end
end
