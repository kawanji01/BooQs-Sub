class CreateTranslations < ActiveRecord::Migration[6.0]
  def change
    create_table :translations do |t|
      t.references :article, null: false, foreign_key: true
      t.references :passage, foreign_key: true
      t.text             :text
      t.integer          :lang_number
      t.timestamps
    end
    add_index :translations, :lang_number
  end
end
