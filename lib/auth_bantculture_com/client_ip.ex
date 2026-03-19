defmodule AuthBantcultureCom.ClientIP do
  @moduledoc false

  alias AuthBantcultureCom.CIDR

  @cloudflare_cidrs [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32"
  ]

  def effective_ip(conn) do
    remote_ip = conn.remote_ip

    if trusted_cloudflare_proxy?(remote_ip) do
      conn
      |> Plug.Conn.get_req_header("cf-connecting-ip")
      |> List.first()
      |> parse_header_ip(remote_ip)
    else
      remote_ip
    end
  end

  def format_ip(ip_tuple), do: ip_tuple |> :inet.ntoa() |> to_string()

  def subnet_string({a, b, c, _d}), do: Enum.join([a, b, c], ".") <> ".0/24"

  def subnet_string({a, b, c, _d, _e, _f, _g, _h}) do
    [a, b, c]
    |> Enum.map(&Integer.to_string(&1, 16))
    |> Enum.join(":")
    |> Kernel.<>("::/48")
  end

  defp trusted_cloudflare_proxy?(ip), do: Enum.any?(@cloudflare_cidrs, &CIDR.match?(ip, &1))

  defp parse_header_ip(nil, fallback), do: fallback

  defp parse_header_ip(value, fallback) do
    case :inet.parse_address(String.to_charlist(String.trim(value))) do
      {:ok, parsed} -> parsed
      _ -> fallback
    end
  end
end
