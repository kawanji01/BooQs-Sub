class TranslationCreationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(article_uid, translation_type, lang_code, locale, user_uid)
    article = Article.find_param(article_uid)
    lang_number = Lang.convert_code_to_number(lang_code)

    # タイトルにまで翻訳がついていないなら、youtubeからタイトルの翻訳も取得する。
    if article.title_translations.find_by(lang_number: lang_number).blank?
      translated_title = Youtube.get_translated_title(article.reference_url, lang_code)
      # return ifの早期リターンで抜けようとするとsidekiqの処理そのものが終了してしまったので、ifをネストした。
      if translated_title.present?
        article.title_translation_new(lang_number, translated_title)
        # translation_of_title = article.title_translation_new(lang_number, translated_title)
        # translation_of_title.separate_text
      end
    end

    file_name = "translation-#{translation_type}_#{article_uid}_#{user_uid}"

    # translationに取り込むためのCSVを作成する。
    is_auto = translation_type == 'auto-generated'
    # 字幕のSRTをダウンロードする。
    file, error = Youtube.download_sub_srt(file_name, article.reference_url, lang_code, is_auto)
    return if error.present?

    # SRTをpassageに取り込めるようにCSVに変換する。その際、SRTの重複表現を消す。
    csv = Youtube.convert_srt_into_csv(file, lang_number, true)
    return if csv.blank?

    file_name_csv = "translation-#{lang_code}_#{article_uid}_#{user_uid}.csv"
    uploaded_file_url = FileUtility.upload_file_and_get_s3_path(csv, file_name_csv)

    # CSV.parseについて。https://docs.ruby-lang.org/ja/latest/method/CSV/s/parse.html
    # S3のCSVを開く方法 https://qiita.com/ironsand/items/0211ad6773d22cbc1263
    translations_csv = CSV.parse(open(uploaded_file_url).read, headers: true)
    translations_count = translations_csv.length
    translations_csv.each_with_index do |row, i|
      # htmlタグ＆末尾の不要な改行を取り除く。
      text = Sanitize.clean(row['text'].strip)
      # lang_numberがわかっているなら、それを引数で渡して設定したほうがいい。
      lang_number = row['lang_number'].to_i if lang_number.blank?
      lang_number = Lang.return_lang_number(text) if lang_number.blank?
      lang_number = article.lang_number if lang_number.blank?
      next if text.blank?

      start_time = row['start_time'].to_d
      end_time = row['end_time'].to_d

      # start_timeとend_timeの平均から、翻訳の参照元のpassageを決定する。
      average_time = (start_time + end_time) * 0.5
      passage = article.passages.find { |p| p.start_time <= average_time && p.end_time >= average_time }
      next if passage.blank?
      # passageと同じ言語の翻訳は作らない。
      next if passage.lang_number == lang_number

      # whereではなくfindで検索しているのは、前回のイテレーションでbuildしたtranslationも検索範囲に含めたいから。
      if (translation = passage&.translations&.find { |t| t&.lang_number == lang_number })
        # 参照元候補のpassageに、対象言語の翻訳がすでについているなら、参照元候補のpassageの翻訳に、翻訳をマージする。
        text = [translation.text, text].join("\n")
        translation.text = text.strip
      else
        passage.translations.build(article: article,
                                   text: text,
                                   lang_number: lang_number)
      end
      passage.save
      # translation.separate_text
      ActionCable.server.broadcast 'progress_bar_channel',
                                   content_id: article_uid,
                                   user_id: user_uid,
                                   all_count: translations_count,
                                   process_count: i,
                                   redirect_url: "/#{locale}/articles/#{article_uid}?sub=#{lang_code}"
    end

    if article.save && Rails.env.production?
      # 使い終わったCSVをS３から消す
      FileUtility.delete_s3_tmp_file(file_name_csv)
    else
      Open3.capture3("rm tmp/#{file_name_csv}")
    end
    ActionCable.server.broadcast 'progress_bar_channel',
                                 content_id: article_uid,
                                 user_id: user_uid,
                                 all_count: translations_count,
                                 process_count: translations_count,
                                 redirect_url: "/#{locale}/articles/#{article_uid}?sub=#{lang_code}"
  end
end
