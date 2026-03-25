defmodule AuthBantcultureCom.AuthGate do
  @moduledoc false

  alias AuthBantcultureCom.AuthThrottle
  alias AuthBantcultureCom.ClientIP
  alias AuthBantcultureCom.IpAccessEntry
  alias AuthBantcultureCom.Repo

  def submit(conn, entered_password) do
    ip = ClientIP.effective_ip(conn)
    ip_string = ClientIP.format_ip(ip)
    subnet = ClientIP.subnet_string(ip)
    password = entered_password |> to_string() |> String.trim() |> String.downcase()

    with :ok <- AuthThrottle.allowed?(ip_string),
         true <- valid_password?(password, passwords()),
         {:ok, _entry} <- record_success(subnet, password) do
      AuthThrottle.clear(ip_string)

      {:ok,
       %{
         effective_ip: ip_string,
         subnet: subnet,
         redirect_url: Application.fetch_env!(:auth_bantculture_com, :success_redirect_url)
       }}
    else
      {:error, :throttled} ->
        {:error, :throttled}

      false ->
        AuthThrottle.record_failure(ip_string)
        append_denied(subnet, password, ip_string)
        {:error, :invalid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp passwords do
    :auth_bantculture_com
    |> Application.fetch_env!(:passwords_path)
    |> File.read!()
    |> String.split(~r/\R/, trim: true)
    |> Enum.map(&String.downcase(String.trim(&1)))
    |> Enum.reject(&(&1 == ""))
  end

  defp valid_password?("", _passwords), do: false

  defp valid_password?(entered, passwords) do
    Enum.any?(passwords, fn candidate -> secure_compare?(entered, candidate) end)
  end

  defp secure_compare?(left, right) when byte_size(left) == byte_size(right),
    do: Plug.Crypto.secure_compare(left, right)

  defp secure_compare?(_left, _right), do: false

  defp record_success(subnet, password) do
    Repo.insert(%IpAccessEntry{ip: subnet, password: password, granted_at: timestamp()})
  end

  defp append_denied(subnet, password, ip_string) do
    line =
      subnet <>
        "#" <> password <> " " <> NaiveDateTime.to_string(timestamp()) <> ip_string <> "\n"

    File.write(Application.fetch_env!(:auth_bantculture_com, :access_denied_log_path), line, [
      :append
    ])
  end

  defp timestamp do
    NaiveDateTime.local_now() |> NaiveDateTime.truncate(:second)
  end
end
