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
    respond_to do |format|
      format.html { redirect_to root_url }
      format.js
    end
  end


  private
  
  def extract_user_language
    available = %w[ja en]
    @user_language = http_accept_language.preferred_language_from(available)
  end

end
