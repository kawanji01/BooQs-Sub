class StaticPagesController < ApplicationController
  before_action :extract_user_language

  def home; end
  
  def transcriber
    @breadcrumb_hash = { t('subtitles.download_subtitles_on_youtube') => root_path,
                         t('subtitles.transcribe_videos_on_youtube') => '' }
  end


  private
  
  def extract_user_language
    available = %w[ja en]
    @user_language = http_accept_language.preferred_language_from(available)
  end

end
