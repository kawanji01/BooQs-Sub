class CreatePassages < ActiveRecord::Migration[6.0]
  def change
    create_table :passages do |t|
      t.references :article, foreign_key: true
      t.text             :text
      t.integer          :lang_number
      t.float            :start_time
      t.integer          :start_time_minutes
      t.float            :start_time_seconds
      t.float            :end_time
      t.integer          :end_time_minutes
      t.float            :end_time_seconds
      t.timestamps
    end
    add_index :passages, :lang_number
  end
end
