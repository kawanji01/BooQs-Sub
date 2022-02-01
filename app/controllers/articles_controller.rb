class ArticlesController < ApplicationController
  def index
    @articles = Article.all.order(created_at: :desc)
  end

  def show
    @article = Article.find_param(params[:id])
    @related_articles = Article.all.sample(6)
    # passage_idがnilなら、そのtranslationは消去法でarticeのtitleの翻訳
    @title_translation = @article.find_title_translation(@lang_number_of_translation)

    @passages = if @article.video?
                  @article.passages.order(start_time: :asc).page(params[:page]).per(10)
                else
                  @article.passages.order(created_at: :asc).page(params[:page]).per(10)
                end

    @translated_lang_numbers = @article.translations.group(:lang_number).count.keys
    @tags = @article.tags

    @video_id = Youtube.get_video_id(@article.reference_url)
    # assets_pipelineでprecompileしたjsだと、gonの変数が更新されない問題があるので、上記の変数でviewを通じてjsでvideoIDをとってくるようにした。
    # gon.videoId = Youtube.get_video_id(@article.reference_url)
    @processing = params[:processing] if params[:processing].present?

    @breadcrumb_hash = {t('articles.articles') => root_path,
                        @article.title => ''}

  end

  def new
    @article = Article.new
  end

  def create
    @user = current_user
    @article = current_user.articles.build(article_params)
    @article.set_attributes_for_create
    @article.chapter = @chapter if @chapter.present?
    @article.separate_all_text if @article.valid?

    if @article.save_and_create_addition_request(request.remote_ip)
      @article.notify_subscribers_of_posting
      flash[:success] = t('articles.article_created')
      redirect_to @article
    else
      flash[:danger] = t('articles.article_failed_to_create')
      render 'articles/new'
    end
  end

  def new_video
    @article = Article.new(reference_url: params[:article][:reference_url])
    @valid = Youtube.youtube_url?(@article.reference_url)
    return if @valid == false

    snippet = Youtube.get_snippet(@article.reference_url)
    @article.title = Youtube.get_title(snippet)
    @article.scraped_image = Youtube.get_thumbnail(snippet)
    @tags = Youtube.get_tags(snippet)
    lang_code_of_title = Youtube.get_default_language(snippet)
    @article.lang_number = Lang.convert_code_to_number(lang_code_of_title)
    @audio_lang = Youtube.get_default_audio_language(snippet)
    @article.lang_number_of_audio = Lang.convert_code_to_number(@audio_lang)
    # APIからタイトルとサムネを取得できなかった場合はmetainscpectorを使ってスクレイピングする。
    @article.scrape_youtube_url if @article.title.blank? || @article.scraped_image.blank?
    @article.set_attributes_for_create
    @sub_lang_list = Youtube.importable_sub_lang_list(@article.reference_url, @audio_lang)

    # 手動字幕がないか、手動字幕にオーディオ言語の字幕がない場合、自動字幕をデフォルトのインポート対象にする。
    if @sub_lang_list[:manual_sub_codes].blank? || @sub_lang_list[:manual_sub_codes].exclude?(@audio_lang)
      @audio_lang = "auto-#{@audio_lang}"
    end

    # セレクトフォームに渡すValueを設定する。
    if @sub_lang_list[:lang_codes].present?
      @sub_lang_codes = @sub_lang_list[:lang_codes]
      @sub_lang_codes.push(nil)
    else
      @sub_lang_codes = [nil]
      @audio_lang = nil
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def create_video
    @article = Article.new(article_params)
    @article.video = true
    @user_uid = SecureRandom.uuid
    @article.set_attributes_for_create
    # @article.tag_list = params[:article][:tag_list]
    # @article.separate_all_text if @article.valid?
    if @article.save
      # @article.notify_subscribers_of_posting
      flash[:success] = t('articles.creating_video_succeeded')
      @article_uid = @article.public_uid
    else
      flash[:danger] = t('articles.creating_video_failed')
      redirect_to new_video_articles_url
    end

    # 自動字幕読み込み
    if params[:article][:sub_lang_code].include?('auto-')
      # 自動字幕の言語コード
      lang_code = params[:article][:sub_lang_code].sub('auto-', '')
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)
      PassageCreationWorker.perform_async(@article_uid, 'auto-generated', lang_code, @locale, @user_uid)
    elsif params[:article][:sub_lang_code].present?
      lang_code = params[:article][:sub_lang_code]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)
      PassageCreationWorker.perform_async(@article_uid, 'manual-sub', lang_code, @locale, @user_uid)
    else
      # ユーザーが取り込む字幕に「なし」を選んだ場合。
      @error = "not importing any caption"
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end


  def new_passages_via_srt
    @article = Article.find_param(params[:id])
    respond_to do |format|
      format.html do
        redirect_to @article
      end
      format.js
    end
  end

  def create_passages_via_srt
    @article = Article.find_param(params[:id])
    return if params[:article][:file].blank?

    file = File.open(params[:article][:file].path, 'r')
    #file = open_srt_file(params[:article][:file])
    @article_uid = @article.public_uid
    @user_uid = current_user.public_uid
    lang_number = params[:article][:lang_number].to_i
    return if file.blank?

    csv = Youtube.convert_srt_into_csv(file, lang_number, false)
    # CSVをs3にアップロードして、ファイルのpathを手に入れる。
    token = SecureRandom.uuid
    file_name = "#{token}.csv"
    uploaded_file_url = FileUtility.upload_file_and_get_s3_path(csv, file_name)
    ImportFileAsPassagesWorker.perform_async(uploaded_file_url, file_name, lang_number, @article_uid, @user_uid, @locale)
    flash[:success] = t 'articles.passages_updated'
  end

  def new_translations_via_srt
    @article = Article.find_param(params[:id])
    respond_to do |format|
      format.html do
        redirect_to @article
      end
      format.js
    end
  end

  def create_translations_via_srt
    @article = Article.find_param(params[:id])
    return if params[:article][:file].blank?

    file = File.open(params[:article][:file].path, 'r')
    @article_uid = @article.public_uid
    @user_uid = current_user.public_uid
    lang_number = params[:article][:lang_number].to_i
    return if file.blank?

    csv = Youtube.convert_srt_into_csv(file, lang_number, false)
    # CSVをs3にアップロードして、ファイルのpathを手に入れる。
    token = SecureRandom.uuid
    file_name = "#{token}.csv"
    uploaded_file_url = FileUtility.upload_file_and_get_s3_path(csv, file_name)
    ImportFileAsTranslationsWorker.perform_async(uploaded_file_url, file_name, lang_number, @article_uid, @user_uid, @locale)
    flash[:success] = t 'articles.passages_updated'
  end


  def form_to_translate_all
    @article = Article.find_param(params[:id])
    # refererからsubを取ってくる必要があるので、@lagn_of_translationは使えない。
    @trans_lang = request.referer[/sub=(.+)/, 1].presence || current_user&.return_lang_code
    @trans_lang_number = Lang.convert_code_to_number(@trans_lang)
    @lang_array = ApplicationController.helpers.lang_form_array

    @deepl_supported = Lang.deepl_supported_languages.include?(@lang_of_translation)
    @characters_count = @article.characters_count
    @amount = @article.translation_fee

    respond_to do |format|
      format.html { redirect_to article_path(@article) }
      format.js
    end
  end

  def checkout_translation
    @user = current_user
    @article = Article.find_param(params[:id])
    price = ENV['ALL_TRANSLATION_PRICE_ID']
    lang_number = params[:article][:lang_number_of_translation].to_i
    lang_code = Lang.convert_number_to_code(lang_number)
    deepl = params[:type_of_translator] == 'deepl' && Lang.deepl_supported_languages.include?(lang_code)
    if lang_code.blank?
      redirect_to @article
    elsif (customer = @user.customer)
      @session = Stripe::Checkout::Session.create({
                                                      customer: customer.stripe_customer_id,
                                                      line_items: [{
                                                                       price: price,
                                                                       quantity: 1,
                                                                   }],
                                                      payment_method_types: [
                                                          'card',
                                                      ],
                                                      mode: 'payment',
                                                      locale: @locale,
                                                      success_url: request.base_url + "/#{@locale}/articles/#{@article.public_uid}/success_translation?lang_code=#{lang_code}&deepl=#{deepl}&session_id={CHECKOUT_SESSION_ID}",
                                                      cancel_url: article_url(@article),
                                                  })
    else
      @session = Stripe::Checkout::Session.create({
                                                      customer_email: @user.email,
                                                      line_items: [{
                                                                       price: price,
                                                                       quantity: 1,
                                                                   }],
                                                      payment_method_types: [
                                                          'card',
                                                      ],
                                                      mode: 'payment',
                                                      locale: @locale,
                                                      success_url: request.base_url + "/#{@locale}/articles/#{@article.public_uid}/success_translation?lang_code=#{lang_code}&deepl=#{deepl}&session_id={CHECKOUT_SESSION_ID}",
                                                      cancel_url: article_url(@article),
                                                  })
    end
  end

  def success_translation
    return redirect_to @article if params[:session_id].blank?

    @user = current_user
    @article = Article.find_param(params[:id])
    lang_code = params[:lang_code]
    deepl = ActiveRecord::Type::Boolean.new.cast(params[:deepl])
    flash[:success] = t 'articles.translating_all_succeeded'
    TranslateAllWorker.perform_async(@article.public_uid, lang_code, @locale, @user&.public_uid, deepl)
  end


  def edit
    @article = Article.find_param(params[:id])
  end

  def update
    @article = Article.find_param(params[:id])
    @article.assign_attributes(article_params)
    # start_time_minutesとstart_time_secondsをまとめて秒換算する。
    @article.set_start_time

    if @article.save
      flash[:success] = t('articles.update_succeeded')
      redirect_to @article
    else
      flash[:success] = t('articles.update_failed')
      render 'articles/edit'
    end
  end

  def edit_title
    @article = Article.find_param(params[:id])
  end

  def update_title
    @article = Article.find_param(params[:id])
    @user = current_user
    return if @article.title_modification_permitted_by(@user) == false

    comment = params[:comment]
    ip = request.remote_ip
    @chapter = @article.chapter
    @article.assign_attributes(article_params)
    @article.set_lang_number
    @valid = @article.valid?
    return if @valid == false

    @article.separate_text if params[:separateText].present?
    request = @article.create_modification_request(current_user, comment, ip)
    if @article.screen_requests?(current_user)
      @article = Article.find_param(@article.public_uid)
      @message = t('article_requests.modification_request_submitted')
      request.notify_author_of_being_proposed
    else
      @article.merge_with(request)
      @message = t('articles.title_updated')
      # 画像の縦横比を保存する。
      @article.update_width_and_height_of_image
      request.notify_article_changed_without_screening
      user_icon = ApplicationController.helpers.icon_for(request.user)
      ActionCable.server.broadcast 'title_modification_channel',
                                   html: render(partial: 'articles/article_title', locals: {article: @article}),
                                   article: @article,
                                   message: @message,
                                   user_name: (request.user.present? ? request.user.name : t('users.anonymous_user')),
                                   user_icon: user_icon
    end
  end

  def cancel
    @article = Article.find_param(params[:id])
  end

  # モバイルでの翻訳切り替えボタン
  def select_translation
    @article = Article.find_param(params[:id])
    @translated_lang_numbers = @article.translations.group(:lang_number).count.keys
    @current_lang_code = request.referer[/sub=(.+)/, 1].presence
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  # 「他の言語の翻訳を作成する」ボタンから表示するモーダル
  def new_translation
    @article = Article.find_param(params[:id])
    @translated_lang_numbers = @article.translations.group(:lang_number).count.keys
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def destroy
    @article = Article.find_param(params[:id])
    @chapter = @article&.chapter
    @article.destroy
    flash[:success] = '記事を削除しました。'
    if @chapter.present?
      redirect_to chapter_url(@chapter)
    else
      redirect_to root_url
    end
  end

  def download_subtitles
    data = @article.create_subtitles_srt
    file_name = @article.title
    send_data(data, filename: "#{file_name}.srt")
  end

  def download_translations
    lang_number = params[:download_lang_number].to_i
    data = @article.create_translations_srt(lang_number)
    file_name = if @article&.find_title_translation(lang_number).present?
                  @article.find_title_translation(lang_number)
                else
                  "#{@article.title}_#{Lang.convert_number_to_code(lang_number)}"
                end
    send_data(data, filename: "#{file_name}.srt")
  end


  def passage_importer
    @article = Article.find_param(params[:id])
    @audio_lang = Lang.convert_number_to_code(@article.lang_number_of_audio)
    @sub_lang_list = Youtube.importable_sub_lang_list(@article.reference_url, @audio_lang)
    # 手動字幕がないか、手動字幕にオーディオ言語の字幕がない場合、自動字幕をデフォルトのインポート対象にする。
    if @sub_lang_list[:manual_sub_codes].blank? || @sub_lang_list[:manual_sub_codes].exclude?(@audio_lang)
      @audio_lang = "auto-#{@audio_lang}"
    end
    # セレクトフォームに渡すValueを設定する。
    @sub_lang_codes = if @sub_lang_list[:lang_codes].present?
                        @sub_lang_list[:lang_codes]
                      end
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def import_passages
    @article = Article.find_param(params[:id])
    @article_uid = @article.public_uid
    @user_uid = SecureRandom.uuid

    # 自動字幕読み込み
    if params[:article][:sub_lang_code].include?('auto-')
      # 自動字幕の言語コード
      lang_code = params[:article][:sub_lang_code].sub('auto-', '')
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      # 原文の重複や乱れを防ぐために、インポートする前にすべての原文（と翻訳）を削除する。
      @article.delete_all_passages
      # workerの書き込みとの競合を防ぐために、workerの処理まで３秒開ける。
      sleep(3)
      PassageCreationWorker.perform_async(@article_uid, 'auto-generated', lang_code, @locale, @user_uid)
    elsif params[:article][:sub_lang_code].present?
      lang_code = params[:article][:sub_lang_code]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      @article.delete_all_passages
      sleep(3)
      PassageCreationWorker.perform_async(@article_uid, 'manual-sub', lang_code, @locale, @user_uid)
    end
    flash[:success] = t('articles.creating_caption_succeeded')

    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def translation_importer
    @article = Article.find_param(params[:id])
    @audio_lang = Lang.convert_number_to_code(@article.lang_number_of_audio)
    @sub_lang_list = Youtube.importable_sub_lang_list(@article.reference_url, @audio_lang)
    # 手動字幕がないか、手動字幕にオーディオ言語の字幕がない場合、自動字幕をデフォルトのインポート対象にする。
    if @sub_lang_list[:manual_sub_codes].blank? || @sub_lang_list[:manual_sub_codes].exclude?(@audio_lang)
      @audio_lang = "auto-#{@audio_lang}"
    end
    # セレクトフォームに渡すValueを設定する。
    @sub_lang_codes = if @sub_lang_list[:lang_codes].present?
                        @sub_lang_list[:lang_codes]
                      end
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def import_translations
    @article = Article.find_param(params[:id])
    @article_uid = @article.public_uid
    @user_uid = SecureRandom.uuid


    # 自動字幕読み込み
    if params[:article][:sub_lang_code].include?('auto-')
      # 自動字幕の言語コード
      lang_code = params[:article][:sub_lang_code].sub('auto-', '')
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      # 重複を防ぐために、インポートする前に指定言語の翻訳をすべてリセットする。
      @article.translations&.where(lang_number: Lang.convert_code_to_number(lang_code))&.delete_all
      # workerの書き込みとの競合を防ぐために、workerの処理まで３秒開ける。
      sleep(3)
      TranslationCreationWorker.perform_async(@article_uid, 'auto-generated', lang_code, @locale, @user_uid)
    elsif params[:article][:sub_lang_code].present?
      lang_code = params[:article][:sub_lang_code]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      @article.translations&.where(lang_number: Lang.convert_code_to_number(lang_code))&.delete_all
      sleep(3)
      TranslationCreationWorker.perform_async(@article_uid, 'manual-sub', lang_code, @locale, @user_uid)
    end
    flash[:success] = t('articles.creating_caption_succeeded')

    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def passage_file_importer
    @article = Article.find_param(params[:id])
  end

  def import_passage_file
    @article = Article.find_param(params[:id])
    @user_uid = SecureRandom.uuid
    return if params[:article][:file].blank?

    file = File.open(params[:article][:file].path, 'r')
    @article_uid = @article.public_uid
    lang_number = params[:article][:lang_number].to_i
    return if file.blank?

    csv = Youtube.convert_srt_into_csv(file, lang_number, false)
    # CSVをs3にアップロードして、ファイルのpathを手に入れる。
    token = SecureRandom.uuid
    file_name = "#{token}.csv"
    uploaded_file_url = FileUtility.upload_file_and_get_s3_path(csv, file_name)
    # 原文の重複や乱れを防ぐために、インポートする前にすべての原文（と翻訳）を削除する。
    @article.delete_all_passages
    # workerの書き込みとの競合を防ぐために、workerの処理まで３秒開ける。
    sleep(3)
    PassageFileImportWorker.perform_async(uploaded_file_url, file_name, lang_number, @article_uid, @user_uid, @locale)
    flash[:success] = t 'articles.passages_updated'
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def translation_file_importer
    @article = Article.find_param(params[:id])
  end

  def import_translation_file
    @article = Article.find_param(params[:id])
    @user_uid = SecureRandom.uuid
    return if params[:article][:file].blank?

    file = File.open(params[:article][:file].path, 'r')
    @article_uid = @article.public_uid
    lang_number = params[:article][:lang_number].to_i
    return if file.blank?

    csv = Youtube.convert_srt_into_csv(file, lang_number, false)
    # CSVをs3にアップロードして、ファイルのpathを手に入れる。
    token = SecureRandom.uuid
    file_name = "#{token}.csv"
    uploaded_file_url = FileUtility.upload_file_and_get_s3_path(csv, file_name)
    # 重複や文の乱れを防ぐために、インポートする前に指定言語の翻訳を、タイトル以外の翻訳以外はすべて削除する。
    @article.translations&.where(lang_number: lang_number, title: false)&.delete_all
    # workerの書き込みとの競合を防ぐために、workerの処理まで３秒開ける。
    sleep(3)
    TranslationFileImportWorker.perform_async(uploaded_file_url, file_name, lang_number, @article_uid, @user_uid, @locale)
    flash[:success] = t 'articles.translations_updated'
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  private

  def article_params
    params.require(:article).permit(:title,
                                    :lang_number, :lang_number_of_audio,
                                    :reference_url, :scraped_image,
                                    :video,
                                    # レコードにはないが、送信したいパラメーター
                                    :tag_list)
  end

end
