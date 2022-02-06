class AddVideoUidToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :youtube_id, :string
    add_index :articles, :youtube_id
  end
end
