defmodule AuthBantcultureCom.ClientIP do
  @moduledoc false

  alias AuthBantcultureCom.CIDR

  @trusted_gateway_cidrs [
    "127.0.0.0/8",
    "::1/128"
  ]

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

    ip =
      cond do
        trusted_gateway_proxy?(remote_ip) ->
          conn
          |> Plug.Conn.get_req_header("x-forwarded-for")
          |> List.first()
          |> parse_forwarded_for(remote_ip)

        trusted_cloudflare_proxy?(remote_ip) ->
          conn
          |> Plug.Conn.get_req_header("cf-connecting-ip")
          |> List.first()
          |> parse_header_ip(remote_ip)

        true ->
          remote_ip
      end

    normalize_ip(ip)
  end

  def format_ip(ip_tuple), do: ip_tuple |> normalize_ip() |> :inet.ntoa() |> to_string()

  def subnet_string(ip) do
    case normalize_ip(ip) do
      {a, b, c, _d} ->
        Enum.join([a, b, c], ".") <> ".0/24"

      {a, b, c, _d, _e, _f, _g, _h} ->
        [a, b, c]
        |> Enum.map(&Integer.to_string(&1, 16))
        |> Enum.join(":")
        |> Kernel.<>("::/48")
    end
  end

  defp trusted_cloudflare_proxy?(ip), do: Enum.any?(@cloudflare_cidrs, &CIDR.match?(ip, &1))
  defp trusted_gateway_proxy?(ip), do: Enum.any?(@trusted_gateway_cidrs, &CIDR.match?(ip, &1))

  defp parse_header_ip(nil, fallback), do: fallback

  defp parse_header_ip(value, fallback) do
    case :inet.parse_address(String.to_charlist(String.trim(value))) do
      {:ok, parsed} -> normalize_ip(parsed)
      _ -> fallback
    end
  end

  defp parse_forwarded_for(nil, fallback), do: fallback

  defp parse_forwarded_for(value, fallback) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.find_value(&parse_forwarded_ip/1)
    |> case do
      nil -> fallback
      ip -> ip
    end
  end

  defp parse_forwarded_ip(value) do
    case :inet.parse_address(String.to_charlist(value)) do
      {:ok, parsed} -> normalize_ip(parsed)
      _ -> nil
    end
  end

  defp normalize_ip({0, 0, 0, 0, 0, 0xFFFF, high, low})
       when high in 0..0xFFFF and low in 0..0xFFFF do
    {
      Bitwise.bsr(high, 8),
      Bitwise.band(high, 0xFF),
      Bitwise.bsr(low, 8),
      Bitwise.band(low, 0xFF)
    }
  end

  defp normalize_ip(ip), do: ip
end
