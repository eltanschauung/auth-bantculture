defmodule AuthBantcultureCom.ClientIPTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias AuthBantcultureCom.ClientIP

  test "uses cf-connecting-ip only for trusted cloudflare proxies" do
    conn =
      conn(:get, "/")
      |> Map.put(:remote_ip, {173, 245, 48, 10})
      |> Plug.Conn.put_req_header("cf-connecting-ip", "198.51.100.9")

    assert ClientIP.effective_ip(conn) == {198, 51, 100, 9}
  end

  test "ignores spoofed cf-connecting-ip from untrusted remotes" do
    conn =
      conn(:get, "/")
      |> Map.put(:remote_ip, {203, 0, 113, 7})
      |> Plug.Conn.put_req_header("cf-connecting-ip", "198.51.100.9")

    assert ClientIP.effective_ip(conn) == {203, 0, 113, 7}
  end

  test "uses x-forwarded-for from the trusted local gateway" do
    conn =
      conn(:get, "/")
      |> Map.put(:remote_ip, {127, 0, 0, 1})
      |> Plug.Conn.put_req_header("x-forwarded-for", "198.51.100.10")

    assert ClientIP.effective_ip(conn) == {198, 51, 100, 10}
  end

  test "formats ipv4 and ipv6 subnets like the php app" do
    assert ClientIP.subnet_string({203, 0, 113, 9}) == "203.0.113.0/24"

    assert ClientIP.subnet_string({0x2606, 0x4700, 0x1234, 0, 0, 0, 0, 1}) ==
             "2606:4700:1234::/48"
  end

  test "normalizes ipv4-mapped ipv6 addresses back to ipv4" do
    mapped = {0, 0, 0, 0, 0, 0xFFFF, 0x63FE, 0x39BF}

    assert ClientIP.format_ip(mapped) == "99.254.57.191"
    assert ClientIP.subnet_string(mapped) == "99.254.57.0/24"
  end
end
