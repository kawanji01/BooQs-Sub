# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_02_06_015812) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.string "reference_url"
    t.string "scraped_image"
    t.integer "lang_number"
    t.string "public_uid"
    t.boolean "video"
    t.integer "video_duration"
    t.integer "view_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "lang_number_of_audio"
    t.string "youtube_id"
    t.index ["lang_number"], name: "index_articles_on_lang_number"
    t.index ["lang_number_of_audio"], name: "index_articles_on_lang_number_of_audio"
    t.index ["public_uid"], name: "index_articles_on_public_uid"
    t.index ["youtube_id"], name: "index_articles_on_youtube_id"
  end

  create_table "passages", force: :cascade do |t|
    t.bigint "article_id"
    t.text "text"
    t.integer "lang_number"
    t.float "start_time"
    t.integer "start_time_minutes"
    t.float "start_time_seconds"
    t.float "end_time"
    t.integer "end_time_minutes"
    t.float "end_time_seconds"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "characters_count", default: 0, null: false
    t.index ["article_id"], name: "index_passages_on_article_id"
    t.index ["lang_number"], name: "index_passages_on_lang_number"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "translations", force: :cascade do |t|
    t.bigint "article_id"
    t.bigint "passage_id"
    t.text "text"
    t.integer "lang_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "title", default: false, null: false
    t.index ["article_id"], name: "index_translations_on_article_id"
    t.index ["lang_number"], name: "index_translations_on_lang_number"
    t.index ["passage_id"], name: "index_translations_on_passage_id"
  end

  add_foreign_key "passages", "articles"
  add_foreign_key "taggings", "tags"
  add_foreign_key "translations", "articles"
  add_foreign_key "translations", "passages"
end
