class Passage < ApplicationRecord
  belongs_to :article
  has_many :translations, dependent: :destroy
  before_validation :count_characters
  validates :text, presence: true
  validate :lang_number_set


  # バリデーションをかける前に文字数を格納する。
  def count_characters
    self.characters_count = (text.present? ? text.size : 0)
  end

  def lang_number_set
    errors.add(:lang_number, I18n.t('articles.lang_number_error')) if lang_number.blank?
  end

  def start_time_uniqueness
    if Passage.where(article_id: article_id, start_time: start_time).present?
      errors.add(:start_time_seconds, "：この開始時間の原文はすでに存在しています。")
    end
  end

  # NOTE: start_time_secondsとstart_timeがそれぞれ必要なのは、
  # start_time_seconds,minutesが必要な理由： 分と秒で入力できるユーザーフレンドリーな入力フォームを作るため。
  # start_timeが必要な理由： start_timeで昇順でソートして正しい字幕の順番にするため。
  def set_start_time
    self.start_time_minutes = 0 if start_time_minutes.blank?
    self.start_time_seconds = 0 if start_time_seconds.blank?
    self.start_time = (start_time_minutes * 60).to_f + start_time_seconds
  end

  def set_end_time
    self.end_time_minutes = 0 if end_time_minutes.blank?
    self.end_time_seconds = 0 if end_time_seconds.blank?
    self.end_time = (end_time_minutes * 60).to_f + end_time_seconds
  end

  def set_lang_number
    self.lang_number = Lang.return_lang_number(text) if lang_number.nil?
  end

  # 分かち書きすべき文章を分かち書きする
  def separate_text
    return if Lang.text_to_be_separated?(lang_number) == false

    separated_text = Lang.separate_text(text, lang_number)
    self.text = separated_text if separated_text.present?
  end

  # attributesをsaveするまでに必要な処理をまとめたメソッド / Method bunching processes that record needs until saving.
  def set_attributes
    if article.video?
      set_start_time
      set_end_time
    end
    set_lang_number
  end

  # テキストの言語コード（jaやen）を返す
  def lang_code
    Lang.convert_number_to_code(lang_number)
  end

  # wikiリンクを削除したplainなtextを返す
  # TODO: application_helperのsanitize_links(text)に置き換える。
  def plain_text
    # .*?で最短マッチ。 [[]]を持っているテキストを分割して抽出
    # shared/line_with_dictと同じ処理
    text_array = text.split(/(\[{2}.*?\]{2})/)
    plain_text_array = text_array.map do |text|
      if text.match?(/\[{2}.+\]{2}/)
        text.delete("[[,]]").split(/\|/, 2).first
      else
        text
      end
    end
    plain_text_array.join
  end

end
