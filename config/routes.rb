Rails.application.routes.draw do
  root "home#show"

  # Müşteri portalı: giriş yok, talebe gizli bağlantı (token) ile ulaşılır.
  resources :requests, path: "talep", only: %i[new create show], param: :token do
    resource :reply, only: :create, controller: "requester_replies"
  end

  # Temsilci tarafı
  resource :session, only: %i[new create destroy]
  resources :tickets, path: "kuyruk", only: %i[index show] do
    resources :replies, only: :create
    resources :transitions, only: :create
    resource :assignment, only: :update
  end
  resources :demo_scenarios, path: "demo", only: :create

  get "up" => "rails/health#show", as: :rails_health_check
  get "favicon.ico", to: redirect("/icon.svg")
end
