class Article < ApplicationRecord
  has_many :passages, dependent: :destroy
  has_many :translations, dependent: :destroy
  has_many :translations

  validates :title, presence: true
  validate :lang_number_set
  validates :public_uid, uniqueness: true
  # タグ
  acts_as_taggable_on :tags
  # urlのidをランダムな数字にする /gem public_uid
  generate_public_uid generator: PublicUid::Generators::HexStringSecureRandom.new
  
  def lang_number_set
    errors.add(:lang_number, I18n.t('articles.lang_number_error')) if lang_number.blank?
  end



  ##### 便利メソッド START #####

  # 記事の文字数を取得
  def characters_count
    passages.sum { |passage| passage.text.size } + title.size
  end

  # 言語コードを返す
  def lang_code
    Lang.convert_number_to_code(lang_number)
  end

  # １つでも引数の言語の翻訳があるか？
  def has_translation?(lang_number)
    translations.exists?(lang_number: lang_number)
  end

  # passageのsrtを作成する
  def create_subtitles_srt
    array = []
    passages.order(start_time: :asc).each_with_index do |p, i|
      start_time = ApplicationController.helpers.return_play_time_for_srt(p.start_time)
      end_time = ApplicationController.helpers.return_play_time_for_srt(p.end_time)
      text = <<~TEXT
        #{i + 1}
        #{start_time} --> #{end_time}
        #{p.plain_text}
      TEXT
      array << text
    end
    array.join("\n")
  end

  # translationのsrtを作成する
  def create_translations_srt(lang_number)
    return if lang_number.blank?

    array = []
    passages.order(start_time: :asc).each_with_index do |p, i|
      start_time = ApplicationController.helpers.return_play_time_for_srt(p.start_time)
      end_time = ApplicationController.helpers.return_play_time_for_srt(p.end_time)
      translation = p.translations&.find_by(lang_number: lang_number)
      text = <<~TEXT
        #{i + 1}
        #{start_time} --> #{end_time}
        #{translation.plain_text if translation.present?}
      TEXT
      array << text
    end
    array.join("\n")
  end

  def title_translations
    translations.where(passage_id: nil)
  end

  # タイトルを表示
  def display_title(lang_number)
    translated_title = self.translated_title(lang_number)
    # 日本語なら分かち書きを消す。
    return translated_title.gsub(' ', '') if translated_title.present? && lang_number == 44
    return translated_title if translated_title.present?
    return title.gsub(' ', '') if self.lang_number == 44

    title
  end

  # リード文を表示
  def display_lead(lang_number)
    passage = passages.first
    return if passage.blank?
    return passage.text if passage.lang_number == lang_number

    if (translation = passage.translations.find_by(lang_number: lang_number))
      translation.text
    else
      passage.text
    end
  end

  # title_translationよりもget_translationのほうが理解しやすいので、こちらに置き換える
  def find_title_translation(lang_number)
    translations&.find_by(passage_id: nil, lang_number: lang_number)
  end

  # 翻訳されたタイトルを取得する
  def translated_title(lang_number)
    find_title_translation(lang_number)&.text
  end

  # タイトルの翻訳インスタンスを作成する
  def title_translation_new(lang_number, text)
    translations&.build(passage_id: nil, lang_number: lang_number, text: text)
  end

  ##### 便利メソッド END #####


  
  ##### 値の設定処理  START #####
  def set_attributes
    set_lang_number if lang_number.nil?
  end

  def set_attributes_for_create
    associate_with_children
    set_lang_number
    set_children_lang_number
    set_start_time
    set_video_duration
    set_view_count
  end

  def associate_with_children
    passages.each do |p|
      p.article = self
      p.translations.each do |t|
        t.article = self
      end
    end
  end

  def set_lang_number
    self.lang_number = Lang.return_lang_number(title) if lang_number.nil?
  end

  def set_children_lang_number
    title_translations&.each(&:set_lang_number)
    passages.each do |p|
      p.set_lang_number
      p.translations.each(&:set_lang_number)
    end
  end

  def separate_text
    return if Lang.text_to_be_separated?(lang_number) == false

    separated_text = Lang.separate_text(title, lang_number)
    self.title = separated_text if separated_text.present?
  end

  def separate_all_text
    separate_text
    title_translations&.each(&:separate_text)
    passages&.each do |p|
      p.separate_text
      p.translations.each(&:separate_text)
    end
  end

  def set_start_time
    return if video? == false

    passages.each(&:set_start_time)
  end

  def set_video_duration
    return if video? == false

    self.video_duration = Youtube.get_duration(reference_url)
  end

  def set_view_count
    return if video? == false

    self.view_count = Youtube.get_view_count(reference_url)
  end

  def scrape_reference_url
    if reference_url.present? && reference_url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
      # mechanizeだと429 => Net::HTTPTooManyRequests mechanizeが出るので、metainspectorを利用する。
      page = MetaInspector&.new(reference_url)
      self.title = page&.title
      self.scraped_image = page&.images&.best
      set_lang_number
      true
    else
      false
    end
  end

  def scrape_youtube_url
    return false if Youtube.youtube_url?(reference_url) == false

    scrape_reference_url
    self.title = title.gsub(/- YouTube$/, '')
    true
  end

  ##### 値の設定処理  END #####



  ##### public_uid START #####
  def self.find_param(param)
    find_by! public_uid: param
  end

  def to_param
    public_uid
  end

  def g_public_uid
    update(public_uid: SecureRandom.hex(5))
  end
  ##### public_uid END #####
end
