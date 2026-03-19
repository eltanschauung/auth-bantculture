import Config

config :logger, level: :info

config :auth_bantculture_com, AuthBantcultureComWeb.Endpoint,
  cache_static_manifest: nil,
  force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true]
