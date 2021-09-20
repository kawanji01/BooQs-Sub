Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    root to: 'static_pages#home'
    get 'transcriber', to: 'static_pages#transcriber'
    post '/create-checkout-session', to: 'static_pages#create-checkout-session'
    mount Sidekiq::Web => '/sidekiq'
    mount ActionCable.server => '/cable'

    # APIとサービスの「認証情報」の設定
    get '/auth/google_oauth2/callback', to: 'static_pages#home'

    resources :subtitles do
      collection do
        get :select_captions
        post :download_caption
        get :form_to_transcribe
        get :checkout
        get :transcribe
      end
    end

    #resources :wordnet do
    #  collection do
    #    get :home, :en_en_dict, :ja_ja_dict
    #  end
    #end

  end
end
