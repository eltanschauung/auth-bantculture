defmodule AuthBantcultureComWeb.GateControllerTest do
  use AuthBantcultureComWeb.ConnCase, async: false

  alias AuthBantcultureCom.IpAccessEntry
  alias AuthBantcultureCom.Repo

  setup do
    Repo.delete_all(IpAccessEntry)

    previous = [
      success_redirect_url: Application.get_env(:auth_bantculture_com, :success_redirect_url),
      public_auth_url: Application.get_env(:auth_bantculture_com, :public_auth_url)
    ]

    Application.put_env(:auth_bantculture_com, :success_redirect_url, "https://bantculture.com")
    Application.put_env(:auth_bantculture_com, :public_auth_url, "https://bantculture.com/auth")

    on_exit(fn ->
      Enum.each(previous, fn {key, value} ->
        Application.put_env(:auth_bantculture_com, key, value)
      end)
    end)

    :ok
  end

  test "GET /gate returns 204 for allowed ips", %{conn: conn} do
    Repo.insert!(%IpAccessEntry{ip: "198.51.100.0/24", password: "tewi"})

    conn =
      conn
      |> Map.put(:remote_ip, {198, 51, 100, 9})
      |> get("/gate")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "x-auth-bantculture") == ["allow"]
  end

  test "GET /gate redirects blocked ips to the auth url", %{conn: conn} do
    conn =
      conn
      |> Map.put(:remote_ip, {203, 0, 113, 7})
      |> get("/gate")

    assert redirected_to(conn, 302) ==
             "https://bantculture.com/auth?return_to=https%3A%2F%2Fbantculture.com%2Fgate"

    assert get_resp_header(conn, "x-auth-bantculture") == ["deny"]
  end

  test "catch-all redirects allowed requests back to the protected site path", %{conn: conn} do
    Repo.insert!(%IpAccessEntry{ip: "198.51.100.0/24", password: "tewi"})

    conn =
      conn
      |> Map.put(:remote_ip, {198, 51, 100, 9})
      |> get("/bant/res/123.html?foo=bar")

    assert redirected_to(conn, 302) == "https://bantculture.com/bant/res/123.html?foo=bar"
    assert get_resp_header(conn, "x-auth-bantculture") == ["allow"]
  end

  test "catch-all redirects blocked requests to auth with a return target", %{conn: conn} do
    conn =
      conn
      |> Map.put(:remote_ip, {203, 0, 113, 7})
      |> get("/bant/res/123.html?foo=bar")

    assert redirected_to(conn, 302) ==
             "https://bantculture.com/auth?return_to=https%3A%2F%2Fbantculture.com%2Fbant%2Fres%2F123.html%3Ffoo%3Dbar"

    assert get_resp_header(conn, "x-auth-bantculture") == ["deny"]
  end
end
