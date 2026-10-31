require 'rails_helper'

RSpec.describe(ApplicationController) do
  def lazy_keys(node, scope, action = nil)
    action = node.name if node.is_a?(Prism::DefNode)
    key = node.arguments&.arguments&.first if node.is_a?(Prism::CallNode) && node.name == :t
    own = action && key.is_a?(Prism::StringNode) && key.unescaped.start_with?('.') ? ["#{scope}.#{action}#{key.unescaped}"] : []

    own + node.compact_child_nodes.flat_map { |child| lazy_keys(child, scope, action) }
  end

  describe 'lazy translations' do
    subject(:missing) { keys.reject { |key| I18n.exists?(key, :en) } }

    let(:keys) do
      Rails.root.glob('app/controllers/**/*_controller.rb').flat_map do |path|
        scope = path.relative_path_from(Rails.root.join('app/controllers')).to_s.delete_suffix('_controller.rb').tr('/', '.')
        lazy_keys(Prism.parse_file(path.to_s).value, scope)
      end
    end

    it { expect(keys).to(include('broker.users.update.success')) }
    it { is_expected.to(be_empty) }
  end
end
