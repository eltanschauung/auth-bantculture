defmodule AuthBantcultureComWeb do
  @moduledoc false

  def static_paths,
    do: ~w(assets fonts images robots.txt auth)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: AuthBantcultureComWeb.Layouts]

      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      import Phoenix.HTML
      import AuthBantcultureComWeb.CoreComponents
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AuthBantcultureComWeb.Endpoint,
        router: AuthBantcultureComWeb.Router,
        statics: AuthBantcultureComWeb.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
