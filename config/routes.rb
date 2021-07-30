Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'static_pages#home'
  get '/ja_ja_dict', to: 'static_pages#ja_ja_dict'
  get '/en_en_dict', to: 'static_pages#en_en_dict'
end
