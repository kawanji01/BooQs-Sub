class TranslationsController < ApplicationController


  def new
    @passage = Passage.find(params[:passage_id])
    @article = @passage.article
    @editor_token = SecureRandom.uuid
    @lang_code_of_translation = params[:lang_code_of_translation]
    @translation = @passage.translations.build
    source = Lang.convert_number_to_code(@passage.lang_number)
    # target（翻訳結果）がセットされていない場合は、ユーザーの母語を翻訳結果に指定する。
    target = @lang_code_of_translation
    @translation_text = Lang.google_translate(source, target, @passage.text) if source.present? && target.present?
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end


  def create
    @translation = Translation.new(translation_params)
    @passage = @translation.passage
    @article = @passage.article
    @translation.article = @article
    @translation.set_attributes
    @editor_token = params[:editor_token]
    @lang_code_of_translation = Lang.convert_number_to_code(@translation.lang_number)
    @valid = @translation.valid?
    return if @valid == false

    # @translation.separate_text if params[:separateText].present?
    @translation.save
    @message = t('translations.created_message')
    ActionCable.server.broadcast 'translation_modification_channel',
                                 html: render(partial: 'passages/translation',
                                              locals: {translation: @translation, passage: @passage}),
                                 translation: @translation,
                                 lang_code: @lang_code_of_translation,
                                 passage: @passage,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def edit
    @translation = Translation.find(params[:id])
    @passage = @translation.passage
    @article = @translation.article
    @editor_token = SecureRandom.uuid
    @lang_code_of_translation = Lang.convert_number_to_code(@translation.lang_number)
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def update
    @translation = Translation.find(params[:id])
    @passage = @translation.passage
    @article = @passage.article
    @editor_token = params[:editor_token]
    @lang_code_of_translation = Lang.convert_number_to_code(@translation.lang_number)
    @translation.assign_attributes(translation_params)
    @translation.set_attributes
    @valid = @translation.valid?
    return if @valid == false

    # @translation.separate_text if params[:separateText].present?
    @translation.save
    @message = t('translations.updated_message')
    ActionCable.server.broadcast 'translation_modification_channel',
                                 html: render(partial: 'passages/translation',
                                              locals: {passage: @passage, translation: @translation}),
                                 translation: @translation,
                                 lang_code: @lang_code_of_translation,
                                 passage: @passage,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def destroy
    @translation = Translation.find(params[:id])
    @passage = @translation.passage
    @article = @passage.article
    @user = current_user
    return if @article.translation_elimination_permitted_by(@user) == false

    comment = params[:comment]
    ip = request.remote_ip
    request = @translation.create_elimination_request(@user, comment, ip)
    if @article.screen_translation_requests?(@user)
      @message = t('article_requests.elimination_request_submitted')
      request.notify_author_of_being_proposed
    else
      @translation.merge_with(request)
      @message = t('translations.destroyed_message')
      request.notify_article_changed_without_screening

      user_icon = ApplicationController.helpers.icon_for(request.user)
      ActionCable.server.broadcast 'translation_elimination_channel',
                                   html: render(partial: 'passages/translation', locals: {passage: @passage}),
                                   translation: @translation,
                                   lang_code: @lang_code_of_translation,
                                   passage: @passage,
                                   article: @article,
                                   message: @message,
                                   user_name: (request.user.present? ? request.user.name : t('users.anonymous_user')),
                                   user_icon: user_icon,
                                   user_uid: (request.user.present? ? request.user.public_uid : request.ip)
    end
  end

  def new_title
    @article = Article.find_param(params[:article_uid])
    @translation = @article.translations.build
    @editor_token = SecureRandom.uuid
    @lang_code_of_translation = params[:lang_code_of_translation]
    source = Lang.convert_number_to_code(@article.lang_number)
    target = @lang_code_of_translation
    if source.present? && target.present?
      # youtubeの動画に翻訳データがあるなら、そちらを優先して表示する。なかったら機械翻訳を表示する。
      @translation_text = Youtube.get_translated_title(@article.reference_url, target) if @article.video?
      @translation_text = Lang.google_translate(source, target, @article.title) if @translation_text.blank?
    end
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def create_title
    @translation = Translation.new(translation_params)
    @article = @translation.article
    @translation.set_attributes
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
    @valid = @translation.valid?
    return if @valid == false

    @translation.save
    @message = t('translations.created_message')
    ActionCable.server.broadcast 'translation_modification_channel',
                                 html: render(partial: 'translations/title_translation',
                                              locals: { article: @article, translation: @translation }),
                                 translation: @translation,
                                 lang_code: @lang_code_of_translation,
                                 passage: nil,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def edit_title
    @translation = Translation.find(params[:id])
    @article = @translation.article
    @editor_token = SecureRandom.uuid
    @lang_code_of_translation = Lang.convert_number_to_code(@translation.lang_number)
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def update_title
    @translation = Translation.find(params[:id])
    @article = @translation.article
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
    @translation.assign_attributes(translation_params)
    @translation.set_attributes
    @valid = @translation.valid?
    return if @valid == false

    @translation.save
    @message = t('translations.updated_message')
    ActionCable.server.broadcast 'translation_modification_channel',
                                 html: render(partial: 'translations/title_translation',
                                              locals: {article: @article, translation: @translation}),
                                 translation: @translation,
                                 lang_code: @lang_code_of_translation,
                                 passage: nil,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def destroy_title
    @translation = Translation.find(params[:id])
    @translation_id = @translation.id
    @article = @translation.article
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
    @translation.destroy
    @message = t('translations.destroyed_message')
    ActionCable.server.broadcast 'translation_elimination_channel',
                                 html: render(partial: 'translations/title_translation',
                                              locals: { article: @article, translation: nil }),
                                 lang_code: @lang_code_of_translation,
                                 translation: nil,
                                 passage: nil,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def cancel
    @article = (Article.find(params[:article_id]) if params[:article_id].present?)
    @passage = (Passage.find(params[:passage_id]) if params[:passage_id].present?)
    @translation = (Translation.find(params[:translation_id]) if params[:translation_id].present?)
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end


  private

  def translation_params
    params.require(:translation).permit(:id, :_destroy, :article_id, :passage_id, :text, :lang_number)
  end


end
