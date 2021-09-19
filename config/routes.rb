Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    root to: 'static_pages#home'
    get 'transcriber', to: 'static_pages#transcriber'
    mount Sidekiq::Web => '/sidekiq'
    mount ActionCable.server => '/cable'

    resources :subtitles do
      collection do
        get :select_captions
        post :download_caption
        get :form_to_speech_to_text
        post :speech_to_text
      end
    end

    #resources :wordnet do
    #  collection do
    #    get :home, :en_en_dict, :ja_ja_dict
    #  end
    #end

  end
end
