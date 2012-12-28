Coverpage::Application.routes.draw do
  root :to => 'pages#home'
  
  # Named routes associated with complex pages in pages controller
  %w(home contact geolocation subscribe unsubscribe reps hosted_ebooks_trial).each do |action|
    match "/#{action == 'geolocation' ? 'location' : action}" => "pages##{action}", :as => action
  end

  match 'mini_captcha/:action' => 'mini_captcha#show_image', :as => 'mini_captcha'

  # ADMIN (nested)
  # nested admin controller namespace (issues: #292, #282)
  namespace :admin do
    match "/distribution" => "distribution#index", :as => :distribution
    post "/distribution/execute" => "distribution#execute", :as => :execute_distribution
    post "/distribution/asset_select" => "distribution#asset_select", :as => :asset_select_distribution
    post "/distribution/override_recipient_change" => "distribution#override_recipient_change", :as => :override_recipient_change_distribution
    resources :jobs, :only => [:index, :show, :destroy]
    resources :recipients do
      post :select_type, :on => :collection
    end
    resources :specs
    resources :bundles
    resources :coupons
    resources :series, :as => :collections, :controller => :collections do
      post :assign_product, :on => :member
      delete :delete_product, :on => :member
    end
    resources :errata do
      post :format_options, :on => :collection
      post :set_status, :on => :member
    end
    resources :price_changes do
      post :format_options, :on => :collection
    end
    resources :contributors
    resources :contributor_assignments
    resources :assembly_assignments
    resources :bisac_assignments
    resources :related_product_assignments
    resources :product_formats do
      member do
        post :revert_to_version
        get :versions
        get :changeset
        post :changeset
        get :compare
        post :compare
      end
    end
    resources :downloads do
      get :rename, :on => :member
      put :toggle, :on => :member
    end
    resources :editorial_reviews
    resources :excerpts #, :except => [:index]
    resources :formats do
      put :toggle_default, :on => :member
      put :toggle_pdf, :on => :member
      put :toggle_valid, :on => :member
    end
    resources :products do
      collection do
        get :import
        post :import
        get :export
        post :export
        post :auto_complete_for_bisac_subject_literal
        post :select
      end
      member do
        post :revert_to_version
        get :versions
        get :changeset
        post :changeset
        get :compare
        post :compare
        post :assign_link
        delete :delete_link
      end
      resources :links, :except => [:edit, :update]
      resources :errata, :except => [:edit, :update]
      resources :contributors, :except => [:edit, :update]
      resources :editorial_reviews #, :except => [:edit, :update]
      resources :teaching_guides
    end
    # TEST
    # admin.resources :products, :as => :dbgrid, :controller => 'dbgrid', :collection => { :post_data => :post }
    # admin.resources :catalog_requests, :collection => { :export => :get }
    resources :catalog_requests do
      get :export, :on => :collection
    end
    resources :faqs
    resources :headlines
    resources :subjects, :as => :categories, :controller => :categories do
      post :assign_product, :on => :member
      delete :delete_product, :on => :member
    end
    resources :links do
      post :assign_product, :on => :member
      delete :delete_product, :on => :member
    end
    resources :users do
      get :export, :on => :collection
    end
    resources :pages
    resources :sales do
      post :set_status, :on => :member
    end
    resources :testimonials
    resources :teaching_guides
    resources :handouts
  end
  match "/admin" => "admin#show", :as => :admin
  # END ADMIN (nested)
  
  # Public -- placed after admin routes so admin takes precedence
  resources :catalog_requests
  resources :subjects, :as => :categories, :controller => 'categories', :only => [:index, :show]
  resources :contributors, :only => [:index, :show]
  resources :series, :as => :collections, :controller => 'collections', :only => [:index, :show]
  resources :downloads do
    match :click, :on => :member
  end
  get '/downloads/tag/:tag' => 'downloads#tag', :as => 'tag_downloads'
  resources :editorial_reviews do
    post :search, :on => :collection
  end
  resources :teaching_guides, :only => [:index, :show] do
    put :download, :on => :member
  end
  get '/teaching_guides/tag/:tag' => 'teaching_guides#tag', :as => 'tag_teaching_guides'
  resources :handouts, :only => [:index, :show] do
    put :download, :on => :member
  end
  resources :excerpts, :only => [:index] do
    put :click, :on => :member
    get :read, :on => :member
  end
  resources :faqs, :only => [:index, :show] do
    post :search, :on => :collection
  end
  get '/faqs/tag/:tag' => 'faqs#tag', :as => 'tag_faqs'
  resources :headlines, :only => [:index, :show]
  resources :links, :only => [:index, :show] do
    collection do
      get :recommended
      get :popular
      get :search
    end
    put :click, :on => :member
  end
  match '/links/isbn(/:q)' => 'links#search', :as => 'search_links_by_isbn'

  resources :testimonials, :only => [:index]

  # TODO: fix this stuff -- why the ending '_url'?, seems it returns all teams if Admin, your team if other
  #   but it definitely causes a new sales team to not be created (post to sales_teams_url doesn't result in record)
  # map.with_options(:conditions => { 'session[:user][:type]' => 'Admin' }) do |r|
  #   r.team_url '/sales_teams', :controller => 'sales_teams', :action => 'index'
  # end
  # 
  # map.team_url '/team', :controller => 'sales_teams', :action => 'show'

  resources :sales_teams do
    get :commissions, :on => :member
    get :ytd_sales, :on => :member
    resources :sales_reps
  end
  
  resources :sales_zones
  resources :contracts
  resources :customers do
    member do
      get :products
      post :products
    end
  end
  resources :quotes do
    member do
      put :load_cart
      get :export
      post :copy
    end
  end
  resources :specs
  resources :levels, :only => [:index, :show]
  resources :wishlists do
    post :add, :on => :collection
    put :load_cart, :on => :member
    get :export, :on => :member
  end

  resources :products do
    resources :contributors, :only => [:index]
    resources :errata, :except => [:edit, :update]
    resources :links, :only => [:index]
    get :tooltip, :on => :member
    get :tooltipx, :on => :member
  end
  
  controller :shop do
    match '/shop', :action => 'index', :as => 'shop'
    scope '/shop' do
      match '/quick(/:assembly)', :action => 'quick', :as => 'quick'
      match '/export', :action => 'export', :as => 'export'
      match '/export_cart', :action => 'export_cart', :as => 'export_cart'
      post '/add_by_isbn', :action => 'add_by_isbn', :as => 'add_by_isbn'
      match '/add', :action => 'add', :as => 'add_cart'
      post '/add_one', :action => 'add_one', :as => 'add_one'
      post '/update(/:id)', :action => 'update', :as => 'update_cart'
      match '/new_titles', :action => 'new_titles', :as => 'new_titles'
      match '/new_arrivals', :action => 'new_arrivals', :as => 'new_arrivals'
      match '/recent_arrivals', :action => 'recent_arrivals', :as => 'recent_arrivals'
      match '/search_results', :action => 'search_results', :as => 'search_results'
      match '/advanced_search', :action => 'advanced_search', :as => 'advanced_search'
      match '/cart', :action => 'cart', :as => 'cart'
      put '/buy_now/:id', :action => 'buy_now', :as => 'buy_now'
      put '/buy_later/:id', :action => 'buy_later', :as => 'buy_later'
      put '/remove_item/:id', :action => 'remove_item', :as => 'remove_item'
      match '/email/:id', :action => 'email', :as => 'email'
      delete '/destroy_cart', :action => 'destroy_cart', :as => 'destroy_cart'
      post '/enlarge/:id(/:type)', :action => 'enlarge', :as => 'enlarge'
      match '/history', :action => 'history', :as => 'history'
      post '/coupon', :action => 'coupon', :as => 'apply_coupon'
      match '/pid/:pid', :action => 'pid', :as => 'pid'
      match '/isbn/:isbn', :action => 'isbn', :as => 'isbn'
      match '/show(/:id)', :action => 'show', :as => 'show'
    end
  end

  resources :addresses do
    put :toggle_primary, :on => :member
    post :update_province, :on => :collection
  end
  
  controller :specs do
    scope '/checkout', :context => 'checkout' do
      match '/new_spec', :action => 'new', :as => 'checkout_new_spec'
      match '/edit_spec/:id', :action => 'edit', :as => 'checkout_edit_spec'
      delete '/specs/:id', :action => 'destroy', :as => 'checkout_spec'
    end
  end
  controller :addresses do
    scope '/checkout', :context => 'checkout', :address_type => 'ship_address' do
      match '/new_address/:address_type', :action => 'new', :as => 'checkout_new_address'
      match '/edit_address/:id/:address_type', :action => 'edit', :as => 'checkout_edit_address'
      delete '/address/:id', :action => 'destroy', :as => 'checkout_address'
    end
  end

  controller :checkout do
    match '/checkout', :action => 'processing', :as => 'checkout' #:to => 'checkout#processing'
    %w(processing shipping billing review).each do |action|
      match "/checkout/#{action}", :as => "checkout_#{action}", :action => action
    end
    post '/checkout/complete', :action => 'complete'
  end

  controller :account do
    match '/account', :action => 'index', :as => 'account'
    match '/login', :action => 'login', :as => 'login'
    match '/logout', :action => 'logout', :as => 'logout'
    match '/signup', :action => 'signup', :as => 'signup'
    scope '/account' do
      match '/change_password', :action => 'change_password', :as => 'change_password', :via => [:get, :put]
      match '/change_profile', :action => 'change_profile', :as => 'change_profile', :via => [:get, :put]
      match '/forgot_password', :action => 'forgot_password', :as => 'forgot_password'
      match '/reset', :action => 'reset', :as => 'reset'
      match '/downloads', :action => 'downloads', :as => 'downloads_account'
      put '/download/:id', :action => 'download', :as => 'download_account'
      match '/orders', :action => 'orders', :as => 'orders_account'
      match '/order/:id', :action => 'order', :as => 'order_account'
      match '/status_history/:id', :action => 'status_history', :as => 'status_history_account'
      match '/toggle_email_sale_status', :action => 'toggle_email_sale_status', :as => 'toggle_email_sale_status', :via => :put
    end
  end

  # match "account(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "login(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "logout(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "signup(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "addresses(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "checkout(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "admin/users(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }
  # match "admin/sales(/*path)",  :to => redirect { |_, request| "https://" + request.host + ":443" + request.fullpath }

  # Redirect activities to teaching_guides -- Needed for CLP books
  get '/activities' => 'teaching_guides#index'

  # Install the default route as the lowest priority. 
  # In this case, we attempt to access a file from the pages controller based on the path
  match '*path' => 'pages#view', :id => nil, :as => 'public_page'

end
