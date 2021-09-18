class StaticPagesController < ApplicationController


  def home
    available = %w[ja en]
    @user_language = http_accept_language.preferred_language_from(available)
  end

end
