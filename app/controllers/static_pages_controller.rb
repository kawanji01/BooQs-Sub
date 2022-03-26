class StaticPagesController < ApplicationController
  before_action :extract_user_language

  def home
    @articles_count = Article.all.size
    @navbar_displayed = true
    @articles = Article.all.order(created_at: :desc).page(params[:page]).per(12)
  end
  
  def transcriber
    @navbar_displayed = true
    @breadcrumb_hash = { t('static_pages.home') => root_path,
                         t('subtitles.transcribe_videos_on_youtube') => '' }
  end

  def caption_downloader
    @navbar_displayed = true
    @breadcrumb_hash = { t('static_pages.home') => root_path,
                         t('subtitles.download_captions_on_youtube') => '' }
  end

  def preview
    @text = params[:text]
    @lang_number = params[:lang_number].to_i
  end


  private
  
  def extract_user_language
    available = %w[ja en]
    @user_language = http_accept_language.preferred_language_from(available)
  end

end
