Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [:new, :create]
  
  # OAuth routes for social authentication
  get "/auth/:provider/callback", to: "sessions#omniauth_callback"
  get "/auth/failure", to: "sessions#auth_failure"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Playground V2 routes
  get "v2/playground", to: "playground_v2#index"
  post "v2/playground/preview", to: "playground_v2#preview"
  post "v2/playground/completions", to: "playground_v2#completions"
  get "v2/playground/signatures", to: "playground_v2#signatures"
  get "v2/playground/component_schema", to: "playground_v2#component_schema"
  post "v2/playground/parse_component", to: "playground_v2#parse_component"
  post "v2/playground/form_submit_demo", to: "playground_v2#form_submit_demo"

  # Mount the engine for server actions
  mount SwiftUIRails::Engine => "/swift_ui"

  # Commenting out original Playground routes for now, for V2 development
  # root "playground#index"
  
  # resources :playground, only: [:index] do
  #   collection do
  #     post :preview
  #     post :completions
  #     get :signatures
  #   end
  # end
  
  # Compressed data routes for IntelliSense
  get "/compressed_signatures.json", to: "playground_data#signatures"
  get "/compressed_completions.json", to: "playground_data#completions"
  
  # Component testing routes
  get "/test/hero", to: "component_test#hero", as: :test_hero
  
  # Auth component testing routes
  namespace :auth_test do
    get :login
    get :register
    get :combined
    post :login_submit
    post :register_submit
  end
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
