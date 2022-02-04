class StaticPagesController < ApplicationController
  before_action :extract_user_language

  def home
    @articles = Article.all.order(created_at: :desc)
  end
  
  def transcriber
    @breadcrumb_hash = { t('static_pages.home') => root_path,
                         t('subtitles.transcribe_videos_on_youtube') => '' }
  end

  def caption_downloader
    @breadcrumb_hash = { t('static_pages.home') => root_path,
                         t('subtitles.download_subtitles_on_youtube') => '' }
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
