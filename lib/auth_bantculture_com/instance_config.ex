defmodule AuthBantcultureCom.InstanceConfig do
  @moduledoc false

  @default_passwords ["password", "nigel", "whitehouse"]

  def ip_access_passwords do
    config_path()
    |> File.read()
    |> case do
      {:ok, body} ->
        with {:ok, decoded} <- Jason.decode(body),
             passwords when is_list(passwords) <- Map.get(decoded, "ip_access_passwords") do
          passwords
          |> Enum.map(&(to_string(&1) |> String.trim() |> String.downcase()))
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()
          |> case do
            [] -> @default_passwords
            values -> values
          end
        else
          _ -> @default_passwords
        end

      _ ->
        @default_passwords
    end
  end

  def config_path do
    Application.fetch_env!(:auth_bantculture_com, :instance_config_path)
  end
end
