defmodule AuthBantcultureComWeb.ResponseHeaders do
  @moduledoc false

  import Plug.Conn

  def put_auth_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate, max-age=0")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("expires", "0")
    |> put_resp_header(
      "content-security-policy",
      "default-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; img-src 'self' data:; object-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'"
    )
    |> put_resp_header("referrer-policy", "no-referrer")
    |> put_resp_header(
      "permissions-policy",
      "accelerometer=(), camera=(), geolocation=(), gyroscope=(), microphone=(), payment=(), usb=()"
    )
  end
end
