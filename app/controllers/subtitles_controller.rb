class SubtitlesController < ApplicationController

  def select_captions
    @url = params[:url]
    @valid = Youtube.youtube_url?(@url)
    if @valid == false
      @error_message = t('subtitles.error_message_not_youtube')
      return
    end
    @token = SecureRandom.uuid
    # タイトルと画像を取得。
    # mechanizeだと429 => Net::HTTPTooManyRequests mechanizeが出るので、metainspectorを利用する。
    page = MetaInspector&.new(@url)
    @title = page&.title
    @image = page&.images&.best

    @auto_sub_codes = Youtube.importable_auto_sub_lang_list(@url)
    @lang_code = Youtube.get_transcript_list(@url)
    if @auto_sub_codes.present?
      @lang_code.unshift('auto-generated')
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def download_caption
    url = params[:url]
    @token = params[:token]
    file_type = params[:file_type]
    # 自動字幕読み込み
    if params[:transcript] == 'auto-generated'
      # 自動字幕の言語コード
      lang_code = params[:auto_sub_lang_code]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      DownloadAutoSubWorker.perform_async(url, lang_code, @token, file_type, @locale)
    elsif params[:transcript].present?
      lang_code = params[:transcript]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      DownloadSubtitleWorker.perform_async(url, lang_code, @token, file_type, @locale)
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

end
