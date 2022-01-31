class AddLangNumberOfAudioToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :lang_number_of_audio, :integer
    add_index :articles, :lang_number_of_audio
  end
end
