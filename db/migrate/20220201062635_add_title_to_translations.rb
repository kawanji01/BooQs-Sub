class AddTitleToTranslations < ActiveRecord::Migration[6.0]
  def change
    add_column :translations, :title, :boolean, default: false, null: false
  end
end
