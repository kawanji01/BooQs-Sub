class SubtitlesController < ApplicationController

  def select_captions
    @url = params[:url]
    @valid = Youtube.youtube_url?(@url)
    @error_message = t('subtitles.error_message_not_youtube') if @valid == false
    return if @valid == false

    @token = SecureRandom.uuid
    # タイトルと画像を取得。
    page = MetaInspector&.new(@url)
    @title = page&.title
    @image = page&.images&.best

    @auto_sub_codes = Youtube.importable_auto_sub_lang_list(@url)
    @lang_code = Youtube.get_transcript_list(@url)
    @lang_code.unshift('auto-generated') if @auto_sub_codes.present?

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def download_caption
    url = params[:url]
    @token = params[:token]
    # 自動字幕読み込み
    if params[:transcript] == 'auto-generated'
      # 自動字幕の言語コード
      lang_code = params[:auto_sub_lang_code]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      DownloadAutoSubWorker.perform_async(url, lang_code, @token, @locale)
    elsif params[:transcript].present?
      lang_code = params[:transcript]
      return @error = 'Language unsupported' if Lang.lang_code_unsupported?(lang_code)

      DownloadSubtitleWorker.perform_async(url, lang_code, @token, @locale)
    end

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def form_to_speech_to_text
    @url = params[:url]
    @valid = Youtube.youtube_url?(@url)
    @error_message = t('subtitles.error_message_not_youtube') if @valid == false
    return if @valid == false

    @token = SecureRandom.uuid
    # タイトルと画像を取得。
    page = MetaInspector&.new(@url)
    @title = page&.title
    @image = page&.images&.best

    # @amount = @article.speech_to_text_fee
    #bcp47 = Lang.find_all_bcp47(@article.lang_code)
    # if bcp47.present?
    # 英語のような、記事の言語コードでbcp47に対応する言語なら、該当するbcp47を先頭に表示するようにする。
    #  other_bcp47 = Languages::BCP47_MAP.find_all { |k, v| bcp47&.exclude?(k) }&.map { |a| a[0] }
    #  @bcp47 = bcp47 + other_bcp47
    #else
    # ハワイ語のような、記事の言語コードでbcp47に対応しない言語なら、すべてのbcp47をアルファベット順で表示する。
    other_bcp47 = Languages::BCP47_MAP.keys
    @bcp47 = other_bcp47
    #end

    #@intent = Stripe::PaymentIntent.create(
    #  customer: current_user&.customer&.stripe_customer_id,
    #  setup_future_usage: 'off_session',
    #  amount: @amount,
    #  currency: 'jpy'
    #)

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def speech_to_text
    @url = params[:url]
    bcp47_code = params[:bcp47]
    @token = params[:token]
    audio_file_name = "transcription_#{@token}.flac"
    lang_code = Lang.convert_bcp47_to_code(bcp47_code)
    SpeechToTextWorker.perform_async(@url, @token, audio_file_name, bcp47_code, lang_code, @locale)
    respond_to do |format|
      format.html {
        redirect_to root_url
      }
      format.js
    end
  end

end
