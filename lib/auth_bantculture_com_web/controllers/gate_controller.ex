defmodule AuthBantcultureComWeb.GateController do
  use AuthBantcultureComWeb, :controller

  alias AuthBantcultureCom.AccessList
  alias AuthBantcultureCom.ClientIP
  alias AuthBantcultureCom.Redirects
  alias AuthBantcultureComWeb.ResponseHeaders

  def health(conn, _params) do
    conn
    |> ResponseHeaders.put_auth_headers()
    |> send_resp(:no_content, "")
  end

  def check(conn, _params) do
    if AccessList.allowed?(ClientIP.effective_ip(conn)) do
      conn
      |> ResponseHeaders.put_auth_headers()
      |> put_resp_header("x-auth-bantculture", "allow")
      |> send_resp(:no_content, "")
    else
      conn
      |> ResponseHeaders.put_auth_headers()
      |> put_resp_header("x-auth-bantculture", "deny")
      |> redirect_target(Redirects.auth_url(Redirects.requested_success_url(conn)))
    end
  end

  def dispatch(conn, _params) do
    if AccessList.allowed?(ClientIP.effective_ip(conn)) do
      conn
      |> ResponseHeaders.put_auth_headers()
      |> put_resp_header("x-auth-bantculture", "allow")
      |> redirect_target(Redirects.requested_success_url(conn))
    else
      conn
      |> ResponseHeaders.put_auth_headers()
      |> put_resp_header("x-auth-bantculture", "deny")
      |> redirect_target(Redirects.auth_url(Redirects.requested_success_url(conn)))
    end
  end

  defp redirect_target(conn, url) do
    case URI.parse(url) do
      %URI{scheme: nil, host: nil} -> redirect(conn, to: url)
      _ -> redirect(conn, external: url)
    end
  end
end
