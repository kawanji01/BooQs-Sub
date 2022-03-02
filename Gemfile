source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
#ruby '2.6.6'

gem 'rails',      '6.0.3'
gem 'puma',       '4.3.6'
gem 'sass-rails', '5.1.0'
gem 'webpacker',  '4.0.7'
gem 'turbolinks', '5.2.0'
gem 'jbuilder',   '2.9.1'
gem 'bootsnap',   '1.4.5', require: false

# boostrapの導入：https://qiita.com/amatsukix/items/6ec083428df48b166357
gem 'bootstrap', '~> 4.3.0'
gem 'jquery-rails'


# metaタグに特化したパーサ/ https://github.com/metainspector/metainspector
# mechanizeを導入したので削除予定。→ Too Many Requests とかエラーが頻出したのでtitleとogpの取得には引き続きmetainspectorも利用する。
gem 'metainspector'
# youtubeの字幕をXMLからスクレイピングするために導入
gem 'mechanize'

# 非同期処理のために導入
gem 'redis-namespace', '~> 1.8.0'
gem 'sidekiq', '~> 6.1.2'
gem 'sinatra', require: false
# 失敗したキューを補足する
gem 'sidekiq-failures'

# CSV以外のフォーマットへの対応
gem 'roo', '~> 2.8.0'

# スクレイピングしてきたテキストの整形
gem 'sanitize', '~> 5.2.1'
# タグ機能 / 公式：https://github.com/mbleigh/acts-as-taggable-on / 参考：https://ruby-rails.hatenadiary.com/entry/20150225/1424858414
gem 'acts-as-taggable-on', '~> 9.0'
# urlにインクリメンタルな主キー（id）を表示しないためのgem
gem 'public_uid', '~> 2.1.1'
# scrollに対応して自動でコンテンツを読み込む(無限スクロール) ために導入。
gem 'kaminari'
# SEO対策のためのmetaタグ設定
gem 'meta-tags'
# ---Accept-Language HTTPnヘッダーからユーザーの言語設定を読み込むためのgem
gem 'http_accept_language'
# アップローダー。インポートする字幕ファイルなどをS3にあげる。
gem 'carrierwave', '~> 2.0'
# ダウンロードしてきた字幕など、テキストのhtmlタグを取り除くために導入。
gem 'sanitize', '~> 5.2.1'
# ユーザーがアップロードしたSRTファイルなどの一時保存先としてS3を利用する。
gem 'aws-sdk'
# 開発環境からもs3のtmpに字幕をアップロードできるようにする。
gem 'fog-aws',  '2.0.1'

# 用途は、1,文字起こしの料金を計算するためのyoutubeの動画の長さの取得, 2,タイトルの翻訳の取得
gem 'google-api-client', '~> 0.11'
# 文字起こし
gem 'google-cloud-speech'
# 文字起こしするための音声ファイルのアップロード先
gem 'google-cloud-storage'
# Google Cloud Translation / https://cloud.google.com/translate/docs/setup?hl=ja
gem 'google-cloud-translate', '~> 2.1.1'
# DeepLによる翻訳
gem 'deepl-rb', require: 'deepl'
# 決済
gem 'stripe'
# sitemapの作成 ref: https://github.com/kjvarga/sitemap_generator
gem 'sitemap_generator'

group :development, :test do
  # gem 'sqlite3', '1.4.1'
  gem 'pg', '~> 1.2.3'
  gem 'byebug',  '11.0.1', platforms: [:mri, :mingw, :x64_mingw]
  # Rspec / https://qiita.com/tatsurou313/items/c923338d2e3c07dfd9ee
  gem 'rspec-rails', '~> 4.0.1'
  gem 'factory_bot_rails'
  gem 'database_cleaner-active_record'
  # ブラウザとのインターフェース　参考：https://github.com/titusfortner/webdrivers
  gem 'capybara',           '3.28.0'
  gem 'selenium-webdriver', '3.142.4'
  gem 'webdrivers',         '4.1.2'

  # N+1クエリを検出・解決するためのgem
  gem 'bullet'
  # 速度とメモリ消費を計測する
  gem 'rack-mini-profiler', require: false
  # For memory profiling / 上のgemのオプション。メモリ消費を計測できる。
  gem 'memory_profiler'
  # For call-stack profiling flamegraphs /
  # gem 'flamegraph' # プロファイルをグラフにできる。
  gem 'stackprof' # メソッドごとに計測できる。flamegraphと合わせて解説記事 https://qiita.com/kosuke_nishaya/items/21850f46929df3b4944d
  # Rubymineのデバッグ用gem
  gem 'debase'
  gem 'ruby-debug-ide', '~> 0.7.2'
end

group :development do
  gem 'web-console',           '4.0.1'
  gem 'listen',                '3.1.5'
  gem 'spring',                '2.1.0'
  gem 'spring-watcher-listen', '2.0.1'
  # .envにローカルの環境変数を設定するためのgem
  gem 'dotenv-rails'
  gem 'rubocop',       require: false
  gem 'rubocop-rails', require: false
end

group :production do
  gem 'pg', '~> 1.2.3'
end

# Windows ではタイムゾーン情報用の tzinfo-data gem を含める必要があります
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]