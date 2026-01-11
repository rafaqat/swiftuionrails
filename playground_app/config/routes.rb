Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [:new, :create]
  
  # OAuth routes for social authentication
  get "/auth/:provider/callback", to: "sessions#omniauth_callback"
  get "/auth/failure", to: "sessions#auth_failure"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Playground routes
  get "playground", to: "playground#index"
  post "playground/preview", to: "playground#preview"
  post "playground/completions", to: "playground#completions"
  get "playground/signatures", to: "playground#signatures"
  get "playground/component_schema", to: "playground#component_schema"
  post "playground/parse_component", to: "playground#parse_component"
  post "playground/form_submit_demo", to: "playground#form_submit_demo"

  # Mount the engine for server actions
  mount SwiftUIRails::Engine => "/swift_ui"

  # Set root to the playground
  root "playground#index"
  
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
  
  # Component testing routes - only expose in development/test
  if Rails.env.development? || Rails.env.test?
    get "/test/hero", to: "component_test#hero", as: :test_hero

    # Auth component testing routes
    namespace :auth_test do
      get :login
      get :register
      get :combined
      post :login_submit
      post :register_submit
    end
  end
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
