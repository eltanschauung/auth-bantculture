defmodule AuthBantcultureComWeb.PageControllerTest do
  use AuthBantcultureComWeb.ConnCase, async: false

  alias AuthBantcultureCom.IpAccessEntry
  alias AuthBantcultureCom.Repo

  setup do
    base = Path.join(System.tmp_dir!(), "auth-bantculture-#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)

    passwords_path = Path.join(base, "passwords.log")
    denied_path = Path.join(base, "access_denied.log")

    File.write!(passwords_path, "tewi\nyukari\n")
    File.write!(denied_path, "")
    Repo.delete_all(IpAccessEntry)

    previous = [
      passwords_path: Application.get_env(:auth_bantculture_com, :passwords_path),
      access_denied_log_path: Application.get_env(:auth_bantculture_com, :access_denied_log_path),
      success_redirect_url: Application.get_env(:auth_bantculture_com, :success_redirect_url)
    ]

    Application.put_env(:auth_bantculture_com, :passwords_path, passwords_path)
    Application.put_env(:auth_bantculture_com, :access_denied_log_path, denied_path)
    Application.put_env(:auth_bantculture_com, :success_redirect_url, "https://bantculture.com")

    on_exit(fn ->
      Enum.each(previous, fn {key, value} ->
        Application.put_env(:auth_bantculture_com, key, value)
      end)

      File.rm_rf!(base)
    end)

    %{denied_path: denied_path}
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

  test "valid password writes to access entries and shows redirect message", %{conn: conn} do
    conn =
      conn
      |> Map.put(:remote_ip, {173, 245, 48, 10})
      |> put_req_header("cf-connecting-ip", "198.51.100.9")
      |> post("/", %{"password" => "TeWi"})

    page = html_response(conn, 200)
    assert page =~ "Correct. Not being redirected?"

    assert [%IpAccessEntry{ip: "198.51.100.0/24", password: "tewi", granted_at: %NaiveDateTime{}}] =
             Repo.all(IpAccessEntry)
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
end
