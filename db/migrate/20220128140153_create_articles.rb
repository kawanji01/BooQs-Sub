class CreateArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :articles do |t|
      t.string    :title
      t.string    :reference_url
      t.string    :scraped_image
      t.integer   :lang_number
      t.string    :public_uid
      t.boolean   :video
      t.integer   :video_duration
      t.integer   :view_count
      t.timestamps
    end
    add_index :articles, :lang_number
    add_index :articles, :public_uid
  end
end
