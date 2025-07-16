Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Playground routes (unified playground)
  root "playground#index"
  
  resources :playground, only: [:index] do
    collection do
      post :preview
      post :completions
      get :signatures
    end
  end
  
  # Compressed data routes for IntelliSense
  get "/compressed_signatures.json", to: "playground_data#signatures"
  get "/compressed_completions.json", to: "playground_data#completions"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
