module Tools
  class GetTool < BaseTool
    class << self
      def inherited(subclass)
        super
        subclass.annotations(destructive_hint: false, idempotent_hint: true, open_world_hint: false, read_only_hint: true)
      end

      def selection_depth = 1
    end
  end
end
