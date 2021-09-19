class StaticPagesController < ApplicationController
  before_action :extract_user_language

  def home; end
  
  def transcriber; end
  
  private
  
  def extract_user_language
    available = %w[ja en]
    @user_language = http_accept_language.preferred_language_from(available)
  end

end
