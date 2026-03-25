import Config

if System.get_env("PHX_SERVER") do
  config :auth_bantculture_com, AuthBantcultureComWeb.Endpoint, server: true
end

config :auth_bantculture_com,
  passwords_path:
    System.get_env("PASSWORDS_PATH") || Path.expand("../var/passwords.log", __DIR__),
  access_denied_log_path:
    System.get_env("ACCESS_DENIED_LOG_PATH") || Path.expand("../var/access_denied.log", __DIR__),
  success_redirect_url: System.get_env("SUCCESS_REDIRECT_URL") || "https://bantculture.com"

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing. For example: ecto://USER:PASS@HOST/DATABASE"

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing. You can generate one by calling: mix phx.gen.secret"

  host = System.get_env("PHX_HOST") || "auth.bantculture.com"
  port = String.to_integer(System.get_env("PORT") || "4003")

  config :auth_bantculture_com, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")
  config :auth_bantculture_com, AuthBantcultureCom.Repo, url: database_url, pool_size: 5

  config :auth_bantculture_com, AuthBantcultureComWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {127, 0, 0, 1}, port: port],
    secret_key_base: secret_key_base
end
