defmodule AuthBantcultureComWeb.PageController do
  use AuthBantcultureComWeb, :controller

  alias AuthBantcultureCom.AuthGate
  alias AuthBantcultureCom.InstanceConfig
  require Logger

  def home(conn, _params) do
    conn
    |> no_store()
    |> render(:home,
      layout: false,
      error: nil,
      success?: false,
      title: auth_config()["title"],
      message: auth_config()["message"],
      redirect_url: Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
    )
  end

  def submit(conn, %{"password" => password}) do
    case AuthGate.submit(conn, password) do
      {:ok, %{redirect_url: redirect_url}} ->
        conn
        |> no_store()
        |> render(:home,
          layout: false,
          error: nil,
          success?: true,
          title: auth_config()["title"],
          message: auth_config()["message"],
          redirect_url: redirect_url
        )

      {:error, :throttled} ->
        conn
        |> no_store()
        |> put_status(:too_many_requests)
        |> render(:home,
          layout: false,
          error: "Too many attempts. Try again later.",
          success?: false,
          title: auth_config()["title"],
          message: auth_config()["message"],
          redirect_url: Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
        )

      {:error, :invalid} ->
        conn
        |> no_store()
        |> render(:home,
          layout: false,
          error: "Invalid password.",
          success?: false,
          title: auth_config()["title"],
          message: auth_config()["message"],
          redirect_url: Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
        )

      {:error, reason} ->
        Logger.error("auth gate failure: #{inspect(reason)}")

        conn
        |> no_store()
        |> put_status(:internal_server_error)
        |> render(:home,
          layout: false,
          error: "Temporary server problem. Try again later.",
          success?: false,
          title: auth_config()["title"],
          message: auth_config()["message"],
          redirect_url: Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
        )
    end
  end

  defp auth_config, do: InstanceConfig.ip_access_auth_config()

  defp no_store(conn) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, max-age=0")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("expires", "0")
    |> put_resp_header(
      "content-security-policy",
      "default-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; img-src 'self' data:; object-src 'none'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    )
    |> put_resp_header("referrer-policy", "no-referrer")
    |> put_resp_header("permissions-policy", "accelerometer=(), camera=(), geolocation=(), gyroscope=(), microphone=(), payment=(), usb=()")
  end
end
