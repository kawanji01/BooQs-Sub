Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  scope '(:locale)', locale: /#{I18n.available_locales.map(&:to_s).join('|')}/ do
    root to: 'static_pages#home'
    get 'transcriber', to: 'static_pages#transcriber'
    get 'caption_downloader', to: 'static_pages#caption_downloader'
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
    #
    # 記事
    resources :articles do
      member do
        get :download_subtitles
        get :download_translations
        get :new_passages_via_srt
        post :create_passages_via_srt
        get :new_translations_via_srt
        post :create_translations_via_srt
        get :new_translation
        get :select_translation
        get :edit_title
        patch :update_title
        get :cancel
        # 翻訳
        post :batch_translation
        post :translate_in_bulk
        # 翻訳に課金する場合は以下
        get :checkout_translation
        get :success_translation
        # Youtubeから原文と翻訳をインポートする
        post :passage_importer
        post :import_passages
        post :translation_importer
        post :import_translations
        # SRTから原文と翻訳をインポートする。
        post :passage_file_importer
        post :import_passage_file
        post :translation_file_importer
        post :import_translation_file
        # patch :complete
        # get :title_histories
        # get :histories_of_user
        # get :appraisals_of_user
        #  # get :edit_exercise
        #         # patch :update_exercise
        # get :pending_requests
        # get :accepted_requests
        # get :request_setting
      end
      collection do
        get :new_video
        post :create_video
      end
    end


    resources :passages do
      member do
        # get :histories
      end
      collection do
        get :cancel
      end
    end

    # 翻訳 / 記事＆原文＆翻訳の投稿は実験のためにログイン不要にしても良い。問題が起きたら対処する。
    resources :translations do
      member do
        get :histories
        # get :title_histories
      end
      collection do
        get :new_title
        post :create_title
        # ajaxで編集フォームを取り消す。getにしてurlを変更してしまうと、params[:translation]を引き渡せないので、翻訳ボタンが表示されなくなるなど不都合が起きる。
        get :cancel
      end
      member do
        get :edit_title
        patch :update_title
        delete :destroy_title
      end
    end

    resources :tags, only: [:index, :show, :destroy] do
      collection do
        get :article_tags
      end
      member do
        get :articles
      end
    end

    resources :words, only: [:index] do
      collection do
        get :click_search
      end
    end


  end
end
