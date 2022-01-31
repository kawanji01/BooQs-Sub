class Translation < ApplicationRecord
  belongs_to :article
  belongs_to :passage, optional: true

  validates :text, presence: true
  validate :lang_number_set
  validate :lang_number_cannot_be_duplicated


  def lang_number_set
    errors.add(:lang_number, I18n.t('articles.lang_number_error')) if lang_number.blank?
  end

  def lang_number_cannot_be_duplicated
    errors.add(:lang_number, I18n.t('translations.lang_number_cannot_be_duplicated')) if lang_number_unique?
  end

  def lang_number_unique?
    # createではなく、updateの場合、自分が含まれてしまうことで更新できなくなる恐れがあるため、最後に t != self で確認する。
    if passage_targeted? && (t = passage.translations.find_by(lang_number: lang_number)) && t != self
      true
    elsif title_targeted? && (a = article.title_translations.find_by(lang_number: lang_number)) && a != self
      true
    else
      false
    end
  end

  def passage_targeted?
    passage.present?
  end

  def title_targeted?
    passage.blank?
  end

  def set_lang_number
    self.lang_number = Lang.return_lang_number(text) if lang_number.nil?
  end

  def separate_text
    return if Lang.text_to_be_separated?(lang_number) == false

    separated_text = Lang.separate_text(text, lang_number)
    self.text = separated_text if separated_text.present?
  end

  # データをsaveするまでに必要な一連の処理をまとめたメソッド / Method bunching processes that record needs until saving.
  def set_attributes
    set_lang_number
  end

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
