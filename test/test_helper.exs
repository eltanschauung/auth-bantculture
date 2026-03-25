ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(AuthBantcultureCom.Repo, :manual)

case AuthBantcultureCom.Repo.__adapter__().storage_up(AuthBantcultureCom.Repo.config()) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  _ -> :ok
end

owner = Ecto.Adapters.SQL.Sandbox.start_owner!(AuthBantcultureCom.Repo, shared: true)

try do
  Ecto.Adapters.SQL.query!(
    AuthBantcultureCom.Repo,
    """
    CREATE TABLE IF NOT EXISTS ip_access_entries (
      ip varchar NOT NULL,
      password varchar NULL,
      granted_at timestamp NULL
    )
    """,
    []
  )
after
  Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
end
