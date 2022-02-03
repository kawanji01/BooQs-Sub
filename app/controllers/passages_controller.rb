class PassagesController < ApplicationController

  def new
    @article = Article.find(params[:article_id])
    @passage = @article.passages.build
    @lang_code_of_translation = params[:lang_code_of_translation]
    @editor_token = SecureRandom.uuid
    if params[:start_time_minutes].present? && params[:start_time_seconds].present? && params[:start_time].present? && params[:end_time].present?
      @passage.start_time_minutes = params[:start_time_minutes].to_i
      @passage.start_time_seconds = params[:start_time_seconds].to_d + 0.1
      @average = (params[:start_time].to_d + params[:end_time].to_d) / 2.0
    end
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def create
    @passage = Passage.new(passage_params)
    @article = @passage.article
    @lang_code_of_translation = params[:lang_code_of_translation]
    @editor_token = params[:editor_token]
    @passage.set_attributes
    @valid = @passage.valid?
    return if @valid == false

    @passage.save
    @message = t('passages.passage_created')
    ActionCable.server.broadcast 'passage_addition_channel',
                                 html: render(partial: 'passages/passage_with_translation',
                                              locals: {passage: @passage}),
                                 passage: @passage,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def edit
    @passage = Passage.find(params[:id])
    @article = @passage.article
    @editor_token = SecureRandom.uuid
    @lang_code_of_translation = params[:lang_code_of_translation]
    respond_to do |format|
      format.html { redirect_to @article }
      format.js
    end
  end

  def update
    @passage = Passage.find(params[:id])
    @article = @passage.article
    @lang_code_ot_translation = params[:lang_code_of_translation]
    @editor_token = params[:editor_token]
    @passage.assign_attributes(passage_params)
    @passage.set_attributes
    @valid = @passage.valid?
    return if @valid == false

    @passage.save
    @message = t('passages.passage_updated')
    # 画像の縦横比を保存する（現在は審査なしの状態のときだけ更新する）
    # @passage.update_width_and_height_of_image
    ActionCable.server.broadcast 'passage_modification_channel',
                                 html: render(partial: 'passages/passage_with_translation',
                                              locals: {passage: @passage}),
                                 passage: @passage,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def destroy
    @passage = Passage.find(params[:id])
    @article = @passage.article
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
    @passage.destroy
    @message = t('passages.passage_destroyed')
    ActionCable.server.broadcast 'passage_elimination_channel',
                                 html: render(partial: 'passages/empty'),
                                 passage: @passage,
                                 article: @article,
                                 message: @message,
                                 editor_token: @editor_token
  end

  def cancel
    @article = Article.find(params[:article_id])
    @passage = (Passage.find(params[:passage_id]) if params[:passage_id].present?)
    @editor_token = params[:editor_token]
    @lang_code_of_translation = params[:lang_code_of_translation]
  end


  private

  def passage_params
    params.require(:passage).permit(:id, :_destroy, :user_id, :article_id, :text, :lang_number,
                                    :start_time, :start_time_minutes, :start_time_seconds,
                                    :end_time, :end_time_minutes, :end_time_seconds,
    )
  end

end
