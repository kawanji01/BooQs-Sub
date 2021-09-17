class ApplicationController < ActionController::Base
  before_action :set_locale

  # 多言語化
  def set_locale
    I18n.locale = locale
  end

  def locale
    @locale = params[:locale] || I18n.default_locale
  end

end
