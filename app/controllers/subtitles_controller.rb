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

  def form_to_transcribe
    @url = params[:url]
    @valid = Youtube.youtube_url?(@url)
    @error_message = t('subtitles.error_message_not_youtube') if @valid == false
    return if @valid == false

    @duration = Youtube.get_duration(@url)
    @amount = Youtube.get_amount(@duration)
    @price = case @locale.to_s
             when 'en'
               0.5 * @amount.to_f
             when 'ja'
               50 * @amount
             end
    @token = SecureRandom.uuid
    # タイトルと画像を取得。
    page = MetaInspector&.new(@url)
    @title = page&.title
    @image = page&.images&.best
    # ハワイ語のような、記事の言語コードでbcp47に対応しない言語なら、すべてのbcp47をアルファベット順で表示する。
    other_bcp47 = Languages::BCP47_MAP.keys
    @bcp47 = other_bcp47

    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end

  def checkout
    @url = params[:url]
    @bcp47 = params[:bcp47]
    @token = params[:token]
    @valid = Youtube.youtube_url?(@url)
    if @valid
      @duration = Youtube.get_duration(@url)
      @amount = Youtube.get_amount(@duration)
      return redirect_to transcribe_subtitles_url(url: @url, bcp47: @bcp47, token: @token) if @amount.zero?
      
      price = case @locale.to_s
              when 'en'
                ENV['STRIPE_PRICE_TO_TRANSCRIBE_KEY_EN']
              when 'ja'
                ENV['STRIPE_PRICE_TO_TRANSCRIBE_KEY_JA']
              else
                ENV['STRIPE_PRICE_TO_TRANSCRIBE_KEY_EN']
              end
      p  request.base_url
      @session = Stripe::Checkout::Session.create({
                                                    line_items: [{
                                                      price: price,
                                                      quantity: @amount,
                                                    }],
                                                    payment_method_types: [
                                                      'card',
                                                    ],
                                                    mode: 'payment',
                                                    locale: @locale,
                                                    success_url: request.base_url + "/#{@locale}/subtitles/transcribe?url=#{@url}&bcp47=#{@bcp47}&token=#{@token}&session_id={CHECKOUT_SESSION_ID}",
                                                    cancel_url: transcriber_url,
                                                  })
    else
      flash[:danger] = t('subtitles.error_message_not_youtube')
      redirect_to transcriber_url
    end
  end

  def transcribe
    @url = params[:url]
    bcp47_code = params[:bcp47]
    @token = params[:token]
    if @token.present? && bcp47_code.present? && @url.present?
      @duration = Youtube.get_duration(@url)
      @amount = Youtube.get_amount(@duration)
      if @amount.zero? || Stripe::Checkout::Session.retrieve(params[:session_id]).present?
        audio_file_name = "transcription_#{@token}.flac"
        lang_code = Lang.convert_bcp47_to_code(bcp47_code)
        SpeechToTextWorker.perform_async(@url, @token, audio_file_name, bcp47_code, lang_code, @locale)
      end
    else
      redirect_to transcriber_url
    end
  end

end
