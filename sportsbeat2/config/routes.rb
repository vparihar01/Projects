SportsBeat::Application.routes.draw do
  resources :athletes, :only => [:show]
  
  get "dashboard" => "dashboard#index", :as => :dashboard

  get "feeds/:owner_type/:owner_id/:name" => "feeds#show", :as => :feed

  resources :feed_entries, :only => [:show, :destroy]

  resources :games, :only => [:show]

  post "post_to/:subject_type/:subject_id" => "posts#create", :as => :post_to

  resources :posts, :only => [:show, :destroy]

  resources :schools, :only => [:index, :show]

  resources :sports, :only => [:index, :show] do
    member do
      get :positions
    end
  end

  resources :teams, :only => [:show] do
    member do
      get :games
      get :games_nearest
      get :roster
    end
  end

  get "test/upload" => "test#upload"
  post "test/upload" => "test#receive_upload"
  get "test/upload_video" => "test#upload_video"
  post "test/upload_video" => "test#receive_video_upload"

  #get 'users/auth/facebook' => 'omniauth_callbacks#facebook_set_variables'
  devise_for :users, :skip => :registrations, :controllers => { :omniauth_callbacks => "omniauth_callbacks" }
  #devise_for :users
  resources :users, :only => [:index, :show]

  resources :videos, :only => [:show]

  post "zencoder_callback" => "zencoder_callback#create", :as => :zencoder_callback

  root :to => "home#index"
end
