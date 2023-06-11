# frozen_string_literal: true

class DropWebsites < ActiveRecord::Migration[7.0]
  def change
    drop_table('websites', force: :cascade) do |t|
      t.string('domain')
      t.string('copyright_holder')
      t.text('logo_image_data')
      t.text('css')
      t.string('slogan')
      t.text('desc')
      t.text('v_card_logo_base64')
      t.string('sign_out_url')
      t.string('footer_url')
      t.string('modal_url')
      t.string('manifest_url')
      t.string('homepage')
      t.jsonb('manifest')
    end
  end
end
