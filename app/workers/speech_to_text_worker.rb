class SpeechToTextWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often, retry: false
  require 'google/cloud/speech'

  def perform(url, token, file_name, bcp47_lang_code, lang_code, locale)
    lang_number = Lang.convert_code_to_number(lang_code)
    # GCSのbucket
    bucket = FileUtility.get_gcs_bucket(ENV['GOOGLE_PROJECT_ID'], ENV['GOOGLE_BUCKET_NAME'])
    # youtubeから音声をダウンロードして、文字起こしに最適化されたモノラルファイルに変換してから、GCSにアップロードする。
    Youtube.upload_mono_audio_to_gcs(url, file_name, token, bucket)

    client = Google::Cloud::Speech.speech do |config|
      config.credentials = JSON.parse(ENV['GOOGLE_CREDENTIALS'])
    end

    config = {
      language_code: bcp47_lang_code,
      # sample_rate_hertz: 48_000,
      encoding: :FLAC,
      enable_word_time_offsets: true,
      # audio_channel_countについては https://cloud.google.com/speech-to-text/docs/multi-channel
      audio_channel_count: 1
    }
    audio = {
      uri: "gs://audio_for_speech_to_text/#{file_name}"
    }
    # 参考： https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-speech/samples/speech_samples.rb
    operation = client.long_running_recognize config: config, audio: audio

    # name / https://googleapis.dev/ruby/google-cloud-speech-v1/latest/Google/Longrunning/Operation.html
    name = operation.name
    api_key = ENV['GOOGLE_CLOUD_API_KEY']
    # APIkeyを末尾につけないとリクエストを弾かれる / https://qiita.com/r-wakatsuki/items/d867bfb80afc24d96de5
    uri = URI.parse("https://speech.googleapis.com/v1/operations/#{name}?key=#{api_key}")
    progress = 1
    done = ''
    while done != true
      sleep(3)
      # 処理の推移を取得する / 参考：　https://cloud.google.com/speech-to-text/docs/async-recognize?hl=ja#speech_transcribe_async_gcs-protocol
      res = Net::HTTP.get_response(uri)
      hash = JSON.parse(res.body)
      progress = hash['metadata']['progressPercent'].presence || progress
      progress = 99 if progress.to_i == 100
      done = hash['done']
      ActionCable.server.broadcast 'download_transcription',
                                   token: token,
                                   process_count: progress.to_i
    end

    operation.wait_until_done!

    # text_array = []
    # 参考： https://cloud.google.com/speech-to-text/docs/basics?hl=JA
    results = operation.response.results
    # 文字起こしのCSVファイルを作成する
    csv = CSV.generate do |csv|
      # Rubyの%記法。%w(A B)は、[a,b]と同じ。注意点は「,」はいらないこと。
      header = %w[text start_time start_time_minutes start_time_seconds end_time end_time_minutes end_time_seconds lang_number]
      csv << header

      results.each do |r|
        r.alternatives.each do |alternative|
          first_word = alternative.words.first
          last_word = alternative.words.last
          start_time = first_word.start_time.seconds + first_word.start_time.nanos / 1_000_000_000.0
          start_time_minutes = start_time.to_i / 60
          start_time_seconds = (start_time.to_f % 60.0).round(3)
          end_time = last_word.start_time.seconds + last_word.start_time.nanos / 1_000_000_000.0
          end_time_minutes = end_time.to_i / 60
          end_time_seconds = (end_time.to_f % 60.0).round(3)
          text = alternative.transcript
          next if text.blank?

          values = [text, start_time, start_time_minutes, start_time_seconds,
                    end_time, end_time_minutes, end_time_seconds, lang_number]
          csv << values
        end
      end
    end

    srt = Youtube.convert_csv_into_srt(csv)
    txt = Youtube.convert_csv_into_txt(csv)
    # 動画を削除
    FileUtility.delete_file_from_gcs(file_name, bucket)

    # CSVをGCPにアップロード
    #csv_file_name = "csv-#{token}.csv"
    #FileUtility.upload_file_to_gcs(csv, csv_file_name, bucket)
    #csv_file_path = FileUtility.get_file_url(csv_file_name, bucket)
    # SRTをアップロード
    #srt_file_name = "srt-#{token}.srt"
    #FileUtility.upload_file_to_gcs(srt, srt_file_name, bucket)
    #srt_file_path = FileUtility.get_file_url(srt_file_name, bucket)
    # TXTをアップロード
    #txt_file_name = "txt-#{token}.txt"
    #FileUtility.upload_file_to_gcs(txt, txt_file_name, bucket)
    #txt_file_path = FileUtility.get_file_url(txt_file_name, bucket)


    ActionCable.server.broadcast 'download_transcription',
                                 token: token,
                                 csv: csv,
                                 srt: srt,
                                 txt: txt,
                                 message: I18n.t('subtitles.transcription_completed', locale: locale),
                                 process_count: 100
  end

end
