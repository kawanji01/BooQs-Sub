class DownloadSubtitleWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(url, lang_code, token, locale)
    csv = Youtube.scrape_caption_csv(url, lang_code)
    return if csv.blank?

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
