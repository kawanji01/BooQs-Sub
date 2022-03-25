# ユーザーの用意したSTRファイルを翻訳として読み込むWorker
class TranslationFileImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(uploaded_file_url, file_name, lang_number, article_uid, user_uid, locale)
    # CSV.parseについて。https://docs.ruby-lang.org/ja/latest/method/CSV/s/parse.html
    # S3のCSVを開く方法 https://qiita.com/ironsand/items/0211ad6773d22cbc1263
    article = Article.find_param(article_uid)
    lang_code = Lang.convert_number_to_code(lang_number)
    sleep(5)
    translations_csv = CSV.parse(open(uploaded_file_url).read, headers: true)
    translations_count = translations_csv.length
    translations_csv.each_with_index do |row, i|
      text = row['text'].strip
      p text
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

      # 参照元候補のpassageに、対象言語の翻訳がすでについているなら、参照元候補のpassageの翻訳に、翻訳をマージする。
      if (translation = passage.translations&.find { |t| t&.lang_number == lang_number })
        text = [translation.text&.force_encoding('UTF-8'), text.force_encoding('UTF-8')].join("\n")
        translation.text = text
      else
        translation = passage.translations.create(article: article,
                                                  text: text,
                                                  lang_number: lang_number)
      end
      # translation.separate_text
      translation.save
      ActionCable.server.broadcast 'progress_bar_channel',
                                   content_id: article_uid,
                                   user_id: user_uid,
                                   all_count: translations_count,
                                   process_count: i,
                                   redirect_url: "/#{locale}/articles/#{article_uid}?sub=#{lang_code}"
    end


    # 使い終わったCSVをS３から消す
    FileUtility.delete_s3_tmp_file(file_name)
    ActionCable.server.broadcast 'progress_bar_channel',
                                 content_id: article_uid,
                                 user_id: user_uid,
                                 all_count: translations_count,
                                 process_count: translations_count,
                                 redirect_url: "/#{locale}/articles/#{article_uid}?sub=#{lang_code}"
  end
end
