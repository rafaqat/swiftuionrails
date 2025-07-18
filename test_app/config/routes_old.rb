# Copyright 2025
Rails.application.routes.draw do
  # SwiftUI Rails Playground
  get "playground", to: "playground#index"
  post "playground/preview", to: "playground#preview", as: :preview_playground
  
  # Playground V2 (temporary route for development)
  get "playground-v2", to: "playground_v2#index"
  post "playground-v2/preview", to: "playground_v2#preview", as: :preview_playground_v2
  get "playground-v2/signatures", to: "playground_v2#signatures"
  
  # Dogfooding showcase
  get "dogfood", to: "dogfood#index"
  get "dogfood/component_library", to: "dogfood#component_library"
  get "dogfood/patterns", to: "dogfood#patterns"

  namespace :playground do
    resources :completions, only: [ :create ]
  end
  get "playground/signatures", to: "playground#signatures"

  # Custom interactive storybook routes
  get "rails/stories" => "storybook#index"
  get "rails/stories/:story" => "storybook#show", as: :story
  post "storybook/update_preview"
  post "storybook/component_action"
  get "storybook/state_inspector"

  # Legacy storybook routes
  get "storybook/index"
  get "storybook/show"

  # SwiftUI Rails action handling
  namespace :swift_ui do
    resources :actions, only: [ :create ]
  end


  # Stateless components demo
  get "stateless_demo", to: "stateless_demo#index"

  # Rails-first patterns demo
  get "rails_first_demo", to: "rails_first_demo#index"
  post "rails_first_demo/increment_counter", to: "rails_first_demo#increment_counter"
  post "rails_first_demo/add_todo", to: "rails_first_demo#add_todo"
  delete "rails_first_demo/delete_todo/:id", to: "rails_first_demo#delete_todo", as: :delete_todo
  post "rails_first_demo/search", to: "rails_first_demo#search"
  # Test routes
  get "test_grid", to: "application#test_grid"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Component showcase routes
  get "counter", to: "home#counter", as: :counter
  get "debug_demo", to: "home#debug_demo" if Rails.env.development?
  get "home/simple_test", to: "home#simple_test"

  # Product layout examples
  resources :products, only: [ :index ] do
    collection do
      get :catalog
    end
  end

  # Defines the root path route ("/")
  root "home#index"
end
# Copyright 2025
