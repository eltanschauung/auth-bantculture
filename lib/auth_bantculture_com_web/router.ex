defmodule AuthBantcultureComWeb.Router do
  use AuthBantcultureComWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AuthBantcultureComWeb do
    pipe_through :browser

    get "/healthz", GateController, :health
    match :*, "/gate", GateController, :check
    get "/auth", AuthController, :show
    post "/auth", AuthController, :submit
    match :*, "/*path", GateController, :dispatch
  end
end
