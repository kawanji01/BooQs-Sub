class DownloadAutoSubWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(url, lang_code, token, locale)
    file_name = "auto_subtitle_#{lang_code}"
    file, error = Youtube.download_auto_generated_sub_srt(file_name, url, lang_code)
    return if error.present?
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
