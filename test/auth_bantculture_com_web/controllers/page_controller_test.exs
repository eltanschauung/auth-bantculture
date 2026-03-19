defmodule AuthBantcultureComWeb.PageControllerTest do
  use AuthBantcultureComWeb.ConnCase, async: false

  setup do
    base = Path.join(System.tmp_dir!(), "auth-bantculture-#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)

    passwords_path = Path.join(base, "passwords.log")
    access_path = Path.join(base, "access.conf")
    denied_path = Path.join(base, "access_denied.log")

    File.write!(passwords_path, "tewi\nyukari\n")
    File.write!(access_path, "")
    File.write!(denied_path, "")

    previous = [
      passwords_path: Application.get_env(:auth_bantculture_com, :passwords_path),
      access_path: Application.get_env(:auth_bantculture_com, :access_path),
      access_denied_log_path: Application.get_env(:auth_bantculture_com, :access_denied_log_path),
      success_redirect_url: Application.get_env(:auth_bantculture_com, :success_redirect_url)
    ]

    Application.put_env(:auth_bantculture_com, :passwords_path, passwords_path)
    Application.put_env(:auth_bantculture_com, :access_path, access_path)
    Application.put_env(:auth_bantculture_com, :access_denied_log_path, denied_path)
    Application.put_env(:auth_bantculture_com, :success_redirect_url, "https://bantculture.com")

    on_exit(fn ->
      Enum.each(previous, fn {key, value} -> Application.put_env(:auth_bantculture_com, key, value) end)
      File.rm_rf!(base)
    end)

    %{access_path: access_path, denied_path: denied_path}
  end

  test "GET / renders the auth form", %{conn: conn} do
    conn = get(conn, "/")
    page = html_response(conn, 200)
    assert page =~ "KRAKABOOM"
    assert page =~ ~s(name="password")
    assert page =~ ~s(/authlanding2.png)
    assert page =~ ~s(/yotsuba.css)
    assert get_resp_header(conn, "content-security-policy") != []
  end

  test "valid password writes to access file and shows redirect message", %{conn: conn, access_path: access_path} do
    conn =
      conn
      |> Map.put(:remote_ip, {173, 245, 48, 10})
      |> put_req_header("cf-connecting-ip", "198.51.100.9")
      |> post("/", %{"password" => "TeWi"})

    page = html_response(conn, 200)
    assert page =~ "Correct. Not being redirected?"

    written = File.read!(access_path)
    assert written =~ "198.51.100.0/24"
    assert written =~ "#tewi"
    assert written =~ "198.51.100.9"
  end

  test "invalid password writes to denied log", %{conn: conn, denied_path: denied_path} do
    conn =
      conn
      |> Map.put(:remote_ip, {203, 0, 113, 7})
      |> post("/", %{"password" => "wrongpass"})

    page = html_response(conn, 200)
    assert page =~ "Incorrect password."

    written = File.read!(denied_path)
    assert written =~ "203.0.113.0/24#wrongpass"
  end

  test "write failures return a server error", %{conn: conn, access_path: access_path} do
    File.rm!(access_path)
    File.mkdir_p!(access_path)

    conn =
      conn
      |> Map.put(:remote_ip, {173, 245, 48, 10})
      |> put_req_header("cf-connecting-ip", "198.51.100.9")
      |> post("/", %{"password" => "tewi"})

    page = html_response(conn, 500)
    assert page =~ "Temporary server problem. Try again later."
  end

end
