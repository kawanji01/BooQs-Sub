require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WordNetApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    #


    # 2021/02/28 多言語化対応 / 参考：https://qiita.com/tsunemiso/items/bedc7593c7ccd05c395b
    # 言語ファイルを階層ごとに設定するための記述
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    # アプリケーションが対応している言語のホワイトリスト(ja = 日本語, en = 英語)
    # BooQsの対応言語は、https://docs.google.com/spreadsheets/d/e/2PACX-1vTrnDwxVLmjs0delUXjmz0W2MpKYRcJyFFrncVt0vq0WuLfeh3A40YjCIAfDLzeeF0xFWfPhbv88Vi8/pubhtml
    # を参照。
    config.i18n.available_locales = %i(af
sq
am
ar
hy
az
eu
be
bn
bs
bg
ca
ceb
zh-CN
zh-TW
co
hr
cs
da
nl
en
eo
et
fi
fr
fy
gl
ka
de
el
gu
ht
ha
haw
he
hi
hmn
hu
is
ig
id
ga
it
ja
jv
kn
kk
km
rw
ko
ku
ky
lo
la
lv
lt
lb
mk
mg
ms
ml
mt
mi
mr
mn
my
ne
no
ny
or
ps
fa
pl
pt
pa
ro
ru
sm
gd
sr
st
sn
sd
si
sk
sl
so
es
su
sw
sv
tl
tg
ta
tt
te
th
tr
tk
uk
ur
ug
uz
vi
cy
xh
yi
yo
zu)

    # 上記の対応言語以外の言語が指定された場合、エラーとするかの設定
    config.i18n.enforce_available_locales = true

    # デフォルトの言語設定
    #config.i18n.default_locale = :en
    config.i18n.default_locale = :ja

    # ユーザーのlocaleで訳文が見つからない場合、英語のlocaleを返す。
    # fallbackはlocaleの種類によっても詳細にルールを設定できる。参考： https://github.com/ruby-i18n/i18n/wiki/Fallbacks
    config.i18n.fallbacks = [:en]


    # ActiveJobのバックエンドをsidekiqに設定 https://uesaiso.netlify.com/entry/2019/04/06/_20190406sidekiq-on-heroku-redis/#sidekiq%E3%81%AE%E5%B0%8E%E5%85%A5
    config.active_job.queue_adapter = :sidekiq
  end
end
