class CaptionDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(url, lang_code, token, locale, sub_type)
    if sub_type == 'auto-generated'
      file_name = "auto_generated_caption_#{lang_code}"
      is_auto = true
    else
      file_name = "caption_#{lang_code}"
      is_auto = false
    end
    # 字幕のSRTをダウンロードする。
    file, error = Youtube.download_sub_srt(file_name, url, lang_code, is_auto)
    return if error.present?

    #file, error = Youtube.download_auto_generated_sub_srt(file_name, url, lang_code)
    #return if error.present?
    # SRTにCSVに変換する。その際、SRTの重複表現を消す。
    lang_number = Lang.convert_code_to_number(lang_code)

    csv = Youtube.convert_srt_into_csv(file, lang_number, true)
    srt = Youtube.convert_csv_into_srt(csv)
    txt = Youtube.convert_csv_into_txt(csv)
    ActionCable.server.broadcast 'download_file_channel',
                                 token: token,
                                 csv: csv,
                                 srt: srt,
                                 txt: txt,
                                 message: I18n.t('subtitles.download_completed', locale: locale)
  end
end
