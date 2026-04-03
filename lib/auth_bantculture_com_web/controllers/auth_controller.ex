defmodule AuthBantcultureComWeb.AuthController do
  use AuthBantcultureComWeb, :controller

  alias AuthBantcultureCom.AccessList
  alias AuthBantcultureCom.AuthGate
  alias AuthBantcultureCom.ClientIP
  alias AuthBantcultureCom.InstanceConfig
  alias AuthBantcultureCom.Redirects
  alias AuthBantcultureComWeb.ResponseHeaders

  require Logger

  def show(conn, params) do
    if AccessList.allowed?(ClientIP.effective_ip(conn)) do
      conn
      |> ResponseHeaders.put_auth_headers()
      |> redirect_target(Redirects.resolve_return_to(params))
    else
      render_form(conn, params, nil, :ok)
    end
  end

  def submit(conn, %{"password" => password} = params) do
    case AuthGate.submit(conn, password) do
      {:ok, _result} ->
        conn
        |> ResponseHeaders.put_auth_headers()
        |> redirect_target(Redirects.resolve_return_to(params))

      {:error, :throttled} ->
        render_form(conn, params, "Too many attempts. Try again later.", :too_many_requests)

      {:error, :invalid} ->
        render_form(conn, params, "Invalid password.", :ok)

      {:error, reason} ->
        Logger.error("auth gate failure: #{inspect(reason)}")

        render_form(
          conn,
          params,
          "Temporary server problem. Try again later.",
          :internal_server_error
        )
    end
  end

  defp render_form(conn, params, error, status) do
    conn
    |> ResponseHeaders.put_auth_headers()
    |> put_status(status)
    |> render(:auth,
      layout: false,
      error: error,
      return_to: Redirects.resolve_return_to(params),
      title: auth_config()["title"],
      message: auth_config()["message"]
    )
  end

  defp auth_config, do: InstanceConfig.ip_access_auth_config()

  defp redirect_target(conn, url) do
    case URI.parse(url) do
      %URI{scheme: nil, host: nil} -> redirect(conn, to: url)
      _ -> redirect(conn, external: url)
    end
  end
end
