class ApplicationController < ActionController::Base
  before_action :set_locale
  before_action :set_lang

  # 多言語化
  def set_locale
    I18n.locale = locale
  end

  def locale
    @locale = params[:locale] || I18n.default_locale
  end

  # ユーザーの言語設定をグローバル変数でセットする。Articles#showの翻訳文の表示などで利用する。
  def set_lang
    @lang_number_of_locale = Lang.convert_code_to_number(@locale)
    # 表示する翻訳文の言語を設定
    # ページの翻訳文としてもっとも優先的に参照するのは、urlのパラメーター「?sub="言語コード"」にする。
    @lang_of_translation = params[:sub].presence || @locale
    @lang_number_of_translation = Lang.convert_code_to_number(@lang_of_translation)
  end

  # urlやpathヘルパーで自動でロケールを設定させる。
  def default_url_options(options = {})
    options.merge(locale: locale)
  end

  # headerからユーザーの言語を取得する。ユーザー登録時にユーザーのデフォルト言語を設定するために使用。
  def extract_locale_from_accept_language_header
    # available = %w(en ja)
    available = Languages::CODE_MAP.keys
    http_accept_language.preferred_language_from(available)
  end

end
