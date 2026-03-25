defmodule AuthBantcultureCom.InstanceConfig do
  @moduledoc false

  @default_passwords []
  @default_auth_config %{
    "title" => "IP Access Authentication",
    "message" => "Enter a password to gain access."
  }

  def ip_access_passwords do
    case Map.get(config(), "ip_access_passwords") do
      passwords when is_list(passwords) ->
        passwords
        |> Enum.map(&(to_string(&1) |> String.trim() |> String.downcase()))
        |> Enum.reject(&(&1 == ""))
        |> Enum.uniq()
        |> case do
          [] -> @default_passwords
          values -> values
        end

      _ ->
        @default_passwords
    end
  end

  def ip_access_auth_config do
    @default_auth_config
    |> Map.merge(Map.get(config(), "ip_access_auth", %{}))
  end

  def config_path do
    Application.fetch_env!(:auth_bantculture_com, :instance_config_path)
  end

  defp config do
    config_path()
    |> File.read()
    |> case do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, decoded} when is_map(decoded) -> decoded
          _ -> %{}
        end

      _ ->
        %{}
    end
  end
end
