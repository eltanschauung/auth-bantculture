defmodule AuthBantcultureComWeb.Router do
  use AuthBantcultureComWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug AuthBantcultureComWeb.Plugs.BlockDeniedNetworks
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", AuthBantcultureComWeb do
    pipe_through :browser

    get "/", PageController, :home
    post "/", PageController, :submit
  end
end
