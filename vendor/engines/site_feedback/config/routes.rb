SiteFeedback::Engine.routes.draw do
  root to: 'feedbacks#index'
  resources :feedbacks, only: [:create]
end
