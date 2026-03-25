defmodule AuthBantcultureCom.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AuthBantcultureComWeb.Telemetry,
      AuthBantcultureCom.Repo,
      {DNSCluster,
       query: Application.get_env(:auth_bantculture_com, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AuthBantcultureCom.PubSub},
      AuthBantcultureCom.AuthThrottle,
      AuthBantcultureComWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AuthBantcultureCom.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AuthBantcultureComWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
