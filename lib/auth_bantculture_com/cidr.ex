defmodule AuthBantcultureCom.CIDR do
  @moduledoc false

  def match?(ip, cidr) when is_tuple(ip) and is_binary(cidr) do
    with [address, prefix_bits] <- String.split(cidr, "/", parts: 2),
         {prefix, ""} <- Integer.parse(prefix_bits),
         {:ok, network} <- parse_ip(address),
         true <- tuple_size(ip) == tuple_size(network),
         true <- prefix >= 0,
         true <- prefix <= tuple_size(ip) * bits_per_segment(tuple_size(ip)) do
      ip
      |> to_binary()
      |> prefix_binary(prefix)
      |> Kernel.==(prefix_binary(to_binary(network), prefix))
    else
      _ -> false
    end
  end

  defp parse_ip(value) do
    case :inet.parse_address(String.to_charlist(value)) do
      {:ok, parsed} -> {:ok, parsed}
      _ -> :error
    end
  end

  defp bits_per_segment(4), do: 8
  defp bits_per_segment(8), do: 16

  defp to_binary({a, b, c, d}), do: <<a, b, c, d>>

  defp to_binary({a, b, c, d, e, f, g, h}),
    do: <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>

  defp prefix_binary(_binary, 0), do: <<>>

  defp prefix_binary(binary, bits) do
    bytes = div(bits, 8)
    remainder = rem(bits, 8)

    <<prefix::binary-size(bytes), rest::binary>> = binary

    if remainder == 0 do
      prefix
    else
      <<next, _::binary>> = rest
      <<prefix::binary, next::size(remainder)>>
    end
  end
end
