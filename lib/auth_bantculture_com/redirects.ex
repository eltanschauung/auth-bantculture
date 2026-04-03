defmodule AuthBantcultureCom.Redirects do
  @moduledoc false

  @auth_path "/auth"

  def auth_path, do: @auth_path

  def success_base_url do
    Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
  end

  def public_auth_url do
    case Application.get_env(:auth_bantculture_com, :public_auth_url) do
      value when is_binary(value) ->
        value = String.trim(value)
        if value == "", do: nil, else: value

      _ ->
        nil
    end
  end

  def requested_success_url(conn) do
    query = if conn.query_string in [nil, ""], do: nil, else: conn.query_string
    requested_success_url_for_path(conn.request_path, query)
  end

  def requested_success_url_for_path(path, query \\ nil) when is_binary(path) do
    base = URI.parse(success_base_url())
    request_uri = %URI{path: path, query: query}

    base
    |> URI.merge(URI.to_string(request_uri))
    |> URI.to_string()
  end

  def resolve_return_to(params, fallback \\ nil) do
    params
    |> Map.get("return_to")
    |> sanitize_return_to()
    |> case do
      nil -> fallback || success_base_url()
      url -> url
    end
  end

  def auth_url(return_to \\ nil) do
    base = public_auth_url() || @auth_path

    case sanitize_return_to(return_to) do
      nil -> base
      url -> append_query(base, %{"return_to" => url})
    end
  end

  defp sanitize_return_to(nil), do: nil

  defp sanitize_return_to(value) do
    trimmed = value |> to_string() |> String.trim()
    base = URI.parse(success_base_url())

    cond do
      trimmed == "" ->
        nil

      String.starts_with?(trimmed, "/") ->
        trimmed
        |> requested_success_url_for_path()

      true ->
        case URI.parse(trimmed) do
          %URI{scheme: scheme, host: host} = uri when is_binary(scheme) and is_binary(host) ->
            if same_origin?(uri, base), do: URI.to_string(uri), else: nil

          _ ->
            nil
        end
    end
  end

  defp same_origin?(left, right) do
    left.scheme == right.scheme and left.host == right.host and
      normalize_port(left) == normalize_port(right)
  end

  defp normalize_port(%URI{port: nil, scheme: "https"}), do: 443
  defp normalize_port(%URI{port: nil, scheme: "http"}), do: 80
  defp normalize_port(%URI{port: port}), do: port

  defp append_query(url, extra_params) do
    uri = URI.parse(url)
    existing = URI.decode_query(uri.query || "")
    merged = Map.merge(existing, extra_params)

    uri
    |> Map.put(:query, URI.encode_query(merged))
    |> URI.to_string()
  end
end
