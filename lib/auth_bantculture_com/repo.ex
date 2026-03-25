defmodule AuthBantcultureCom.Repo do
  use Ecto.Repo,
    otp_app: :auth_bantculture_com,
    adapter: Ecto.Adapters.Postgres
end
