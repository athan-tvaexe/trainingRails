Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  get "hello", to: "hello#index"
  get "greet", to: "hello#greet"
  post "sum", to: "math#sum_numbers"
  get "weather", to: "weather#index"
  get "weather/bulk", to: "weather#bulk"
  get "convert", to: "exchange#convert"
  post "metadata", to: "metadata#create"
  post "poker", to: "poker#create"
end
