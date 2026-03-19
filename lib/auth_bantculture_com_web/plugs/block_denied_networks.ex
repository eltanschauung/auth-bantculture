defmodule AuthBantcultureComWeb.Plugs.BlockDeniedNetworks do
  @moduledoc false

  import Plug.Conn

  alias AuthBantcultureCom.CIDR
  alias AuthBantcultureCom.ClientIP

  def init(opts), do: opts

  def call(conn, _opts) do
    blocked_cidrs = Application.get_env(:auth_bantculture_com, :blocked_cidrs, [])
    ip = ClientIP.effective_ip(conn)

    if Enum.any?(blocked_cidrs, &CIDR.match?(ip, &1)) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:forbidden, "Forbidden")
      |> halt()
    else
      conn
    end
  end
end
