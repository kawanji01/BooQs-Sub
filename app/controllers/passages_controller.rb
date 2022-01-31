class PassagesController < ApplicationController
  def new
    @article = Article.find(params[:article_id])
    @passage = @article.passages.build
    if params[:start_time_minutes].present? && params[:start_time_seconds].present? && params[:start_time].present? && params[:end_time].present?
      @passage.start_time_minutes = params[:start_time_minutes].to_i
      @passage.start_time_seconds = params[:start_time_seconds].to_f + 0.1
      @average = (params[:start_time].to_f + params[:end_time].to_f) / 2.0
    end
  end

  def create
    @article = Article.find(params[:passage][:article_id])
    @passage = @article.passages.build(passage_params)
    @user = current_user
    return if @article.passage_addition_permitted_by(@user) == false

    comment = params[:comment]
    ip = request.remote_ip
    @passage.set_attributes
    @valid = @passage.valid?
    return if @valid == false

    @passage.separate_text if params[:separateText].present?
    request = @passage.create_addition_request(@user, comment, ip)
    if @article.screen_requests?(@user)
      @message = t('article_requests.addition_request_submitted')
      request.notify_author_of_being_proposed
    else
      @passage.merge_with(request)
      @message = t('passages.passage_created')
      # 画像の縦横比を保存する（現在は審査なしの状態のときだけ更新する）
      @passage.update_width_and_height_of_image
      request.notify_article_changed_without_screening
      user_icon = ApplicationController.helpers.icon_for(request.user)
      ActionCable.server.broadcast 'passage_addition_channel',
                                   html: render(partial: 'passages/passage_with_translation',
                                                locals: { passage: @passage }),
                                   passage: @passage,
                                   article: @article,
                                   message: @message,
                                   user_name: (request.user.present? ? request.user.name : t('users.anonymous_user')),
                                   user_icon: user_icon,
                                   user_uid: request.user&.public_uid
    end
  end

  def edit
    @passage = Passage.find(params[:id])
    @article = @passage.article
  end

  def update
    @passage = Passage.find(params[:id])
    comment = params[:comment]
    ip = request.remote_ip
    @article = @passage.article
    @user = current_user
    return if @article.passage_modification_permitted_by(@user) == false

    @chapter = @article.chapter
    @passage.assign_attributes(passage_params)
    @passage.set_attributes
    @valid = @passage.valid?
    return if @valid == false

    @passage.separate_text if params[:separateText].present?
    request = @passage.create_modification_request(@user, comment, ip)
    if @article.screen_requests?(@user)
      @passage = Passage.find(@passage.id)
      @message = t('article_requests.modification_request_submitted')
      request.notify_author_of_being_proposed
    else
      @passage.merge_with(request)
      @message = t('passages.passage_updated')
      # 画像の縦横比を保存する（現在は審査なしの状態のときだけ更新する）
      @passage.update_width_and_height_of_image
      request.notify_article_changed_without_screening
      user_icon = ApplicationController.helpers.icon_for(request.user)
      ActionCable.server.broadcast 'passage_modification_channel',
                                   html: render(partial: 'passages/passage_with_translation',
                                                locals: { passage: @passage }),
                                   passage: @passage,
                                   article: @article,
                                   message: @message,
                                   user_name: (request.user.present? ? request.user.name : t('users.anonymous_user')),
                                   user_icon: user_icon
    end
  end

  def destroy
    @passage = Passage.find(params[:id])
    @article = @passage.article
    @user = current_user
    return if @article.passage_elimination_permitted_by(@user) == false

    @passage_id = @passage.id
    comment = params[:comment]
    ip = request.remote_ip
    request = @passage.create_elimination_request(@user, comment, ip)
    if @article.screen_requests?(@user)
      @message = t('article_requests.elimination_request_submitted')
      request.notify_author_of_being_proposed
    else
      @passage.merge_with(request)
      @message = t('passages.passage_destroyed')
      request.notify_article_changed_without_screening
      user_icon = ApplicationController.helpers.icon_for(request.user)
      ActionCable.server.broadcast 'passage_elimination_channel',
                                   passage: @passage,
                                   article: @article,
                                   message: @message,
                                   user_name: (request.user.present? ? request.user.name : t('users.anonymous_user')),
                                   user_icon: user_icon
    end
  end

  def cancel
    @article = Article.find(params[:article_id])
    @passage = (Passage.find(params[:passage_id]) if params[:passage_id].present?)
  end



  private

  def passage_params
    params.require(:passage).permit(:id, :_destroy, :user_id, :article_id, :text, :lang_number,
                                    :start_time, :start_time_minutes, :start_time_seconds,
                                    :end_time, :end_time_minutes, :end_time_seconds,
    )
  end

end
