module ApplicationHelper

  def default_meta_tags
    {
      site: 'DiQt Sub',
      title: t('layouts.title'),
      reverse: true,
      charset: 'utf-8',
      description: t('layouts.description'),
      keywords: t('layouts.keywords'),
      canonical: request.original_url,
      separator: '|',
      icon: [
        { href: image_url('favicon/favicon-32x32.png') },
        { href: image_url('BooQs_icon.png'), rel: 'apple-touch-icon', sizes: '180x180', type: 'image/jpg' }
      ],
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: 'website',
        url: request.original_url,
        image: image_url('OGP_diqt.png'),
        locale: @locale
      },
      twitter: {
        card: 'summary',
        site: '@diqtsub_net'
      }
    }
  end

  # 引数の秒数を、シークバーの再生時間と同じフォーマットの文字列に変換して返す。
  def return_play_time(time)
    hours = time.to_i / 3600
    minutes = time.to_i / 60
    # 分数を01のようにする。
    minutes = '0' + minutes.to_s if minutes < 10
    seconds = (time.to_i % 60).round(3)
    # 1.0のような表現を防ぐ。
    seconds = seconds.to_i if seconds.to_s.split('.').second == '0'
    # 秒数を01のようにする
    seconds = '0' + seconds.to_s if seconds < 10

    if hours.zero?
      "#{minutes}:#{seconds}"
    else
      "#{hours}:#{minutes}:#{seconds}"
    end
  end

  # 引数の秒数を、srtファイルの再生時間と同じフォーマットの文字列に変換して返す
  def return_play_time_for_srt(time)
    return "0" if time.blank?
    hours = time.to_i / 3600
    minutes = time.to_i / 60
    # 分数を01のようにする。
    minutes = '0' + minutes.to_s if minutes < 10
    hours = '0' + hours.to_s if hours < 10
    seconds = (time % 60).round(3)

    if seconds < 10
      "#{hours}:#{minutes}:0#{seconds.to_i},000"
    else
      "#{hours}:#{minutes}:#{seconds.to_i},000"
    end
  end

  # 開始時間から終了時間までを文字列で返す。
  def return_play_time_from_start_to_end(start_time, end_time)
    "#{return_play_time(start_time)} ~ #{return_play_time(end_time)}"
  end


  # wikiリンクを取り除いたテキストを返す。
  def sanitize_links(text)
    text.gsub(/(\[{2}.*?\]{2})/) { |s| s.delete("[[,]]").sub(/\|+.*/, '')}
  end

end
