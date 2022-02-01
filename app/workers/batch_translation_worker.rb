class BatchTranslationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(article_uid, lang_code, locale, user_uid, translator_type)
    article = Article.find_param(article_uid)
    translation_lang_number = Lang.convert_code_to_number(lang_code)
    # 翻訳機にdeelpを使うかどうかのboolean
    using_deepl = translator_type == 'deepl'
    # タイトルを翻訳する（タイトルに翻訳がなくて、さらにタイトルの言語と翻訳言語が異なるなら）
    if article.find_title_translation(translation_lang_number).blank? && article.lang_number != translation_lang_number
      # ユーザーが翻訳機にdeeplを選択していて、かつ翻訳対象の言語にdeepLが対応している場合にのみ、deepLを使って翻訳する。
      translation_of_title = article.title_translation_new(translation_lang_number, '')
      translation_of_title.text = if using_deepl
                                    Lang.deepl_translate(article.lang_code, lang_code, article.title)
                                  else
                                    Lang.google_translate(article.lang_code, lang_code, article.title)
                                  end
      # translation_of_title.separate_text
    end
    passages = article.passages
    translations_count = passages.size
    passages.each_with_index do |passage, i|
      i += 1
      # passageの言語と翻訳する言語が同じならスキップ
      next if passage.lang_number == translation_lang_number

      # すでに翻訳がついていた場合は、翻訳をスキップする。
      # next if passage.translations.exists?(lang_number: translation_lang_number)

      text = if using_deepl
               Lang.deepl_translate(passage.lang_code, lang_code, passage.text)
             else
               Lang.google_translate(passage.lang_code, lang_code, passage.text)
             end
      translation = article.translations.build(passage_id: passage.id,
                                               lang_number: translation_lang_number,
                                               text: text)
      # translation.separate_text
      # translation.save
      ActionCable.server.broadcast 'progress_bar_channel',
                                   content_id: article_uid,
                                   user_id: user_uid,
                                   all_count: translations_count,
                                   process_count: i,
                                   redirect_url: "/#{locale}/articles/#{article.public_uid}?sub=#{lang_code}"
    end
    article.save
    ActionCable.server.broadcast 'progress_bar_channel',
                                 content_id: article_uid,
                                 user_id: user_uid,
                                 all_count: translations_count,
                                 process_count: translations_count,
                                 redirect_url: "/#{locale}/articles/#{article.public_uid}?sub=#{lang_code}"
    p 'Success'
  end
end
