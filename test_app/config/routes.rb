# Copyright 2025
Rails.application.routes.draw do
  # Root page - SwiftUI Rails DSL showcase
  root "showcase#index"
  
  # DSL Examples showcase
  resources :showcase, only: [:index] do
    collection do
      get :components      # Basic components showcase
      get :layouts         # Layout components (vstack, hstack, grid, etc.)
      get :forms           # Form components and patterns
      get :animations      # Animation and transitions
      get :responsive      # Responsive design patterns
      get :state_management # State management examples
    end
  end
  
  # Component Gallery
  resources :gallery, only: [:index, :show]
  
  # DSL Patterns
  resources :patterns, only: [:index, :show] do
    collection do
      get :cards
      get :lists
      get :navigation
      get :modals
      get :data_tables
    end
  end
  
  # Interactive Examples (using Turbo)
  resources :examples, only: [:index] do
    collection do
      post :counter        # Counter example with Stimulus
      post :todo_list      # Todo list with Turbo Frames
      post :search         # Live search with Turbo Streams
      post :shopping_cart  # Shopping cart with session state
    end
  end
  
  # SwiftUI Rails Playground (V2 - DSL-powered)
  get "playground", to: "playground_v2#index"
  post "playground/preview", to: "playground_v2#preview", as: :preview_playground
  namespace :playground do
    resources :completions, only: [ :create ]
  end
  get "playground/signatures", to: "playground_v2#signatures"

  # Custom interactive storybook routes
  get "rails/stories" => "storybook#index"
  get "rails/stories/:story" => "storybook#show", as: :story
  post "storybook/update_preview"
  post "storybook/component_action"
  get "storybook/state_inspector"

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
  get "alignment_test", to: "alignment_test#index"
  get "stack_test_playground", to: "stack_test_playground#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end