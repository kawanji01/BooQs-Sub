class DownloadSubtitleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(url, lang_code, token, file_type, locale)
    csv = Youtube.scrape_caption_csv(url, lang_code)
    return if csv.blank?

    case file_type
    when 'csv'
      file = csv
    when 'srt'
      # CSVをSRTに変換する。
      file = Youtube.convert_csv_into_srt(csv)
    when 'txt'
      # 文字起こしのみをTXTに変換する。
      file = Youtube.convert_csv_into_txt(csv)
    end

    ActionCable.server.broadcast 'download_file_channel',
                                 token: token,
                                 file: file,
                                 file_type: file_type,
                                 message: I18n.t('subtitles.download_completed', locale: locale)
  end
end
