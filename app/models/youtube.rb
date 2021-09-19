class Youtube < ApplicationRecord
  require "open-uri"
  require "csv"
  require 'google/apis/youtube_v3'
  # require 'rest-client'
  require 'google/cloud/speech'

  # youtubeのURLかどうかを判別する
  def self.youtube_url?(url)
   if url.present? && url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
     url.include?('https://www.youtube.com/watch?v=') || url.include?('https://youtu.be/')
   else
     false
   end
  end

  # 短縮urlかどうかを確認する。
  def self.short_url?(url)
    url.include?('https://youtu.be/')
  end

  # Youtubeのvideo_idを取得する。
  def self.get_video_id(url)
    return if Youtube.youtube_url?(url) == false

    uri = URI.parse(url)
    if Youtube.short_url?(url)
      uri.path.gsub('/', '')
    else
      query = URI.decode_www_form(uri.query)
      h_query = Hash[query]
      h_query['v']
    end
  end

  def self.get_transcript_list(url)
    video_id = get_video_id(url)
    p url
    p video_id
    file = open("http://video.google.com/timedtext?hl=en&v=#{video_id.to_s}&ts=&type=list&tlangs=1",
                'User-Agent' => 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0')
    xml = Nokogiri::XML(file)
    entries = xml.search('track')
    lang_code = []
    entries.each do |entry|
      lang_code << entry.get_attribute('lang_code')
    end
    lang_code
  end

  # 手動で作られた字幕をスクレイピングして配列に変換する。
  def self.caption_array(url, caption_lang_code)
    video_id = get_video_id(url)
    file = open("http://video.google.com/timedtext?hl=en&v=#{video_id}&ts=&type=track&name=&lang=#{caption_lang_code}",
                'User-Agent' => 'User-Agent: Mozilla/5.0 (Windows NT 6.1; rv:28.0) Gecko/20100101 Firefox/28.0')
    xml = Nokogiri::XML(file)
    texts = xml.search('text')
    array = []
    texts.each do |text|
      start_time = text.get_attribute('start').to_f
      end_time = start_time + text.get_attribute('dur').to_f
      # エスケープ文字を可読な状態に直し(unescape)、htmlタグを削除し（Sanitize）、検索を汚染する幅なしスペースを削除する。 / http://319ring.net/blog/archives/3022/
      text = Sanitize.clean(CGI.unescapeHTML(text.inner_text)).gsub(/[\xe2\x80\x8b]+/, '')
      text_array = [start_time.floor(3), end_time.floor(3), text]
      array << text_array
    end
    array
  end

  # 自動生成字幕のSRTファイルをtmpにダウンロードしてから開く。返り値は、fileとlang_codeとerrorで、処理でエラーが発生したらコントローラー側で早期リターンできるようにする。
  def self.download_auto_generated_sub_srt(file_name, url, lang_code)
    file = nil
    error = nil
    #file_full_name = "#{file_name}_#{article_uid}_#{user_uid}"
    # 順番に処理が終わるのを待って実行するために、systemではなく、Open3,capture3を使う。https://doloopwhile.hatenablog.com/entry/2014/02/04/213641
    #Open3.capture3("youtube-dl --write-auto-sub --sub-lang #{lang_code} --skip-download --output ./tmp/#{file_name} #{url}")
    stdout, stderr, status = Open3.capture3("youtube-dl --write-auto-sub --sub-lang #{lang_code} --skip-download --output ./tmp/#{file_name} #{url}")
    error = "Getting auto-sub failed / #{stderr}" if stderr.present?
    return file, error if error.present?

    Open3.capture3("ffmpeg -i ./tmp/#{file_name}.*.vtt ./tmp/#{file_name}.srt")
    # メモ：ffmpegは標準エラーにログを出力するので、stderrでエラーを捕捉できない。なのでtestコマンドを使ってファイルの変換が成功したかを確認する。 / https://yatta47.hateblo.jp/entry/2015/03/03/231204
    error = 'SRT file not found.' if system("test -e ./tmp/#{file_name}.srt") == false
    return file, error if error.present?

    file = File.open("./tmp/#{file_name}.srt", 'r')
    #res = Open3.capture3("basename ./tmp/#{file_name}.*.vtt .vtt")
    # このlang_codeは、SRTをCSVに変換して非同期にpassagesに読み込むために利用する。
    #lang_code = res.first.strip.gsub("#{file_name}.", '')
    [file, error]
  end

  # SRTをCSVに変換する
  def self.convert_srt_into_csv(srt_file, lang_number = nil, duplication_removed = false)
    previous_text_array = []

    CSV.generate do |csv|
      # 　Rubyの%記法。%w(A B)は、[a,b]と同じ。注意点は「,」はいらないこと。
      header = %w[text start_time start_time_minutes start_time_seconds end_time end_time_minutes end_time_seconds lang_number]
      csv << header

      srt_file.each_line(rs = '') do |paragraph|
        timestamp = paragraph.lines.second
        start_time_srt = timestamp.split(' ').first
        start_time_seconds = start_time_srt.to_time.strftime('%S.%L')
        start_time_minutes = start_time_srt.to_time.strftime('%M')
        start_time = (start_time_seconds.to_f + (start_time_minutes.to_i * 60).to_f).round(3)
        end_time_srt = timestamp.split(' ').last
        end_time_seconds = end_time_srt.to_time.strftime('%S.%L')
        end_time_minutes = end_time_srt.to_time.strftime('%M')
        end_time = (end_time_seconds.to_f + (end_time_minutes.to_i * 60).to_f).round(3)
        # １行目と２行目を取り除いたtextをつくる
        delete_list = [paragraph.lines.first, paragraph.lines.second]
        text_array = paragraph.lines.delete_if { |line| delete_list.include?(line) }
        # youtubeのvvtをsrtに変換したときに発生する、直前のtextとの重複文章を削除する。
        # 重複をきちんと削除できるようにするために、\r\nをすべて\nに統一する。 参考：https://qiita.com/QUANON/items/7c27f4970a2c9063669e
        text_array = text_array.map { |text| text.gsub(/\R/, "\n") }
        text_array = text_array.delete_if { |line| previous_text_array.include?(line) } if duplication_removed
        text = text_array&.join("\n")
        # ３つ以上続けて重複文章がある場合もあるので、重複を排除した後textが空になってしまった場合には、previous_text_arrayを更新しない。
        # そうしないと、A,B,Cすべてにaという文章があったときBのaは削除できるが、Cのaは削除できなくなり、AとCが重複してしまう。
        next if text.blank?

        previous_text_array = text_array

        values = [text, start_time, start_time_minutes, start_time_seconds,
                  end_time, end_time_minutes, end_time_seconds, lang_number]
        csv << values
      end
    end
  end

  def self.convert_csv_into_srt(csv_str)
    array = []
    i = 0
    # 参照： https://docs.ruby-lang.org/ja/latest/method/CSV/s/parse.html
    CSV.parse(csv_str, headers: true).each do |row|
      i += 1
      start_time = ApplicationController.helpers.return_play_time_for_srt(row['start_time'].to_f)
      end_time = ApplicationController.helpers.return_play_time_for_srt(row['end_time'].to_f)
      text = <<~TEXT
        #{i}
        #{start_time} --> #{end_time}
        #{row['text']}
      TEXT
      array << text
    end
    array.join("\n")
  end

  def self.convert_csv_into_txt(csv_str)
    array = []
    CSV.parse(csv_str, headers: true).each do |row|
      text = row['text']
      array << text
    end
    array.join("\n")
  end

  # 手動で作られた字幕をスクレイピングしてCSVに変換する。
  def self.scrape_caption_csv(url, lang_code)
    caption_array = Youtube.caption_array(url, lang_code)
    lang_number = Lang.convert_code_to_number(lang_code)
    CSV.generate do |csv|
      header = %w[text start_time start_time_minutes start_time_seconds end_time end_time_minutes end_time_seconds lang_number]
      csv << header
      caption_array.each do |caption|
        start_time = caption[0]
        start_time_minutes = start_time.to_i / 60
        start_time_seconds = start_time - (start_time_minutes * 60).to_f
        end_time = caption[1]
        end_time_minutes = end_time.to_i / 60
        end_time_seconds = end_time - (end_time_minutes * 60).to_f
        # スクレイピングしてきたhtmlでutf-8にない文字コードがあった場合、分かち書きや他のテキストとの結合時にEncoding::UndefinedConversionErrorやEncoding::CompatibilityErrorが起きる。解決方法：　https://blog.tanebox.com/archives/452/
        text = caption[2]&.force_encoding('UTF-8')
        values = [text, start_time, start_time_minutes, start_time_seconds,
                  end_time, end_time_minutes, end_time_seconds, lang_number]
        csv << values
      end
    end
  end


  # タイトルの翻訳を取得する
  def self.get_translated_title(url, lang_code)
    res = Youtube.get_video_data(url, 'localizations')
    return if res.blank?

    localized_date = res.items.first&.localizations.to_h[lang_code.to_s]
    return if localized_date.blank?

    localized_date.title
  end

  # 動画の再生時間を秒数で返す
  def self.get_duration(url)
    response = Youtube.get_video_data(url, 'contentDetails')
    return if response.blank?

    # 再生時間
    duration = response.items&.first&.content_details&.duration
    return if duration.blank?
    # "PT1M16"(1分16秒)という形式で出力されるので、すべて秒数に直す。
    if /PT(\d*)M/.match(duration).present?
      # 60秒以下の動画に対する処理
      minutes = /PT(\d*)M/.match(duration)[1]
      seconds = /PT\d*M(\d*)/.match(duration)[1]
    else
      minutes = 0
      seconds = /PT(\d*)S/.match(duration)[1]
    end
    minutes.to_i * 60 + seconds.to_i
  end

  def self.get_statics(url)
    response = Youtube.get_video_data(url, 'statistics')
    return if response.blank?

    response
  end

  # 再生回数を取得する
  def self.get_view_count(url)
    response = Youtube.get_statics(url)
    return if response.blank?

    response.items.first&.statistics&.view_count
  end



  # snippetを取得する。
  def self.get_snippet(url)
    Youtube.get_video_data(url, 'snippet')
  end

  # 動画のサムネイルを取得する。
  def self.get_thumbnail(snippet)
    return if snippet.blank?

    # thumbnailsには、小さい順にdefault, medium,high, standardがある。
    snippet.items.first&.snippet&.thumbnails&.standard&.url
  end

  # 動画のタイトルを取得する。
  def self.get_title(snippet)
    return if snippet.blank?

    snippet.items.first.snippet.title
  end

  # 動画のカテゴリーとしてタグを取得する。
  def self.get_tags(snippet)
    return if snippet.blank?

    description = snippet.items.first&.snippet&.description
    # 概要欄で動画投稿者がハッシュタグを用意していたら、それをタグとして採用する。
    # もしハッシュタグないようなら、snippetに用意してある動画のタグを利用する。
    if description.present?
      # ハッシュタグを取得してから#を取り除く。参考：https://qiita.com/corin8823/items/75309761833d823cac6f
      description_tags = description.scan(/[#＃][Ａ-Ｚａ-ｚA-Za-z一-鿆0-9０-９ぁ-ヶｦ-ﾟー]+/)&.map { |hashtag| hashtag&.gsub(/[#＃]/, '')&.strip }
      snippet_tags = snippet.items.first&.snippet&.tags
      return (description_tags + snippet_tags).compact.uniq if description_tags.present? && snippet_tags.present?
      return description_tags.compact.uniq if description_tags.present? && snippet_tags.blank?
      return snippet_tags.compact.uniq if description_tags.blank? && snippet_tags.present?
    else
      snippet.items.first&.snippet&.tags
    end
  end

  # Youtube DATA APIで動画情報を取得する。
  # partには決まった形式を指定する /
  # 参考： https://developers.google.com/youtube/v3/docs/videos?hl=ja / https://developers.google.com/youtube/v3/docs/videos/list?hl=ja
  def self.get_video_data(url, part)
    video_id = get_video_id(url)
    # 参照： https://qiita.com/gyu_outputs/items/af4319258b3d67c57d24
    # https://phpjavascriptroom.com/?t=strm&p=youtubedataapi_v3_list
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.key = ENV['GOOGLE_CLOUD_API_KEY']
    options = {
      id: video_id
    }
    youtube.list_videos(part, options)
  end

  # 音声ファイルをFLACでダウンロードしてきて、音声認識に最適なモノラル音声に変換する。返り値ははモノラルデータのファイルパス。
  def self.download_flac_and_convert_mono(url, id)
    file_name = "./tmp/downloaded_flac_#{id}"
    # メモ： --extract-audioと--outputを同時に使う場合は、-xや-oのように省略して記述してはいけない。
    # また拡張子は.flacではなく%(ext)sの形で指定しないとダウンロードしたファイルが壊れる。
    stdout, stderr, status = Open3.capture3("youtube-dl --extract-audio --audio-format flac --output '#{file_name}.%(ext)s' #{url}")
    p "1:#{stdout}:#{stderr}:#{status}"
    # yotuubeの音声はステレオなので、文字起こしの精度を上げるためにモノラルに分割する / 参考： https://cloud.google.com/solutions/media-entertainment/optimizing-audio-files-for-speech-to-text?hl=ja
    stdout, stderr, status =  Open3.capture3("ffmpeg -i #{file_name}.flac -filter_complex '[0:a]channelsplit=channel_layout=stereo[left][right]' -map '[left]' #{file_name}_FL.flac -map '[right]' #{file_name}_FR.flac")
    p "2:#{stdout}:#{stderr}:#{status}"
    file_name + '_FL.flac'
  end


  # youtubeから音声をダウンロードして、文字起こしに最適化されたモノラルファイルに変換してからGCSにアップロードする。
  def self.upload_mono_audio_to_gcs(url, file_name, token, bucket)
    uid = token
    monaural_file_path = Youtube.download_flac_and_convert_mono(url, uid)
    # bucket = FileUtility.get_gcs_bucket(ENV['GOOGLE_PROJECT_ID'], ENV['GOOGLE_BUCKET_NAME'])
    bucket&.create_file(monaural_file_path, file_name)
    # FileUtility.upload_file_to_gcs(monaural_file, file_name, bucket)
  end

  # ダウンロード可能なyoutubeの自動文字起こし（自動翻訳を含む）の言語コードを取得する。
  def self.importable_auto_sub_lang_list(url)
    list = Open3.capture3("youtube-dl --ignore-config --list-subs #{url}")
    lines = list.first.split("\n")
    lang_codes = []
    is_auto_sub = true
    # ３行目からauto_subの情報
    i = 3
    while is_auto_sub
      # 字幕が一つもなかった場合
      code = lines[i]&.split&.first
      if Lang.lang_code_supported?(code)
        # 一度言語コードを番号に変換してからコードに再変換することで、booqsの対応している言語コードに変換する。
        lang_number = Lang.convert_code_to_number(code)
        lang_code_for_booqs = Lang.convert_number_to_code(lang_number)
        lang_codes << lang_code_for_booqs
        i += 1
      else
        is_auto_sub = false
      end
    end
    lang_codes
  end


end