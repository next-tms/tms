class AddThemeCustomizationFieldsOnBroker < ActiveRecord::Migration[7.0]
  def change
    # Default to Bootstrap 5 default colors
    add_column :brokers, :theme_primary_color, :string, default: '#0d6efd'
    add_column :brokers, :theme_sidebar_background_color, :string, default: '#E2F8FF'
    add_column :brokers, :theme_sidebar_text_color, :string, default: 'rgba(0, 0, 0, 0.95)'
  end
end
