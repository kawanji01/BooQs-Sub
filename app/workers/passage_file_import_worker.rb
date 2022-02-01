class PassageFileImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(uploaded_file_url, file_name, lang_number, article_uid, user_uid, locale)
    article = Article.find_param(article_uid)
    # CSV.parseについて。https://docs.ruby-lang.org/ja/latest/method/CSV/s/parse.html
    # S3のCSVを開く方法 https://qiita.com/ironsand/items/0211ad6773d22cbc1263
    sleep(5)
    passages_csv = CSV.parse(open(uploaded_file_url).read, headers: true)
    passages_count = passages_csv.length
    passages_csv.each_with_index do |row, i|
      text = row['text'].strip
      # CSVにlang_numberが設定されているならそれを採用し、設定されていないならテキストから言語を調査して設定する。
      lang_number = row['lang_number'] if lang_number.blank?
      lang_number = Lang.return_lang_number(text) if lang_number.blank?
      lang_number = article.lang_number if lang_number.blank?
      next if text.blank?

      passage = article.passages.build(text: text,
                                       lang_number: lang_number,
                                       start_time: row['start_time'].to_d,
                                       start_time_minutes: row['start_time_minutes'].to_i,
                                       start_time_seconds: row['start_time_seconds'].to_d,
                                       end_time: row['end_time'].to_d,
                                       end_time_minutes: row['end_time_minutes'].to_i,
                                       end_time_seconds: row['end_time_seconds'].to_d)
      # passage.separate_text
      passage.save
      ActionCable.server.broadcast 'progress_bar_channel',
                                   content_id: article_uid,
                                   user_id: user_uid,
                                   all_count: passages_count,
                                   process_count: i,
                                   redirect_url: "/#{locale}/articles/#{article_uid}"
    end

    # 使い終わったCSVをS３から消す
    FileUtility.delete_s3_tmp_file(file_name)

    ActionCable.server.broadcast 'progress_bar_channel',
                                 content_id: article_uid,
                                 user_id: user_uid,
                                 all_count: passages_count,
                                 process_count: passages_count,
                                 redirect_url: "/#{locale}/articles/#{article_uid}"
  end
end
