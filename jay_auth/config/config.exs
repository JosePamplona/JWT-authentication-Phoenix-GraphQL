# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :jay_auth,
  ecto_repos: [JayAuth.Repo]

# Configures the endpoint
config :jay_auth, JayAuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ac7/vY8fqOHiTSokX1sS95LFDaEWuOWvqgWIUF4MDRiip/v6aqqZXmOBuvghhatb",
  render_errors: [view: JayAuthWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: JayAuth.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :error

config :jay_auth, JayAuth.Guardian,
  issuer: "Jay-Auth",
  secret_key: :crypto.strong_rand_bytes(64) 
              |> Base.url_encode64 
              |> binary_part(0, 64), # "zLj9A/y7FLc/InP70u/Ls0pnieLFd/Xtem8sXSrOTgJyogo9VQM6SWrk7GxgS2Y4", # mix phoenix.gen.secret 
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  token_ttl: %{
    "access" => {20, :seconds},
    "refresh" => {5, :minutes}
  },
  allowed_drift: 2000,
  verify_issuer: true,
  serializer: JayAuth.Guardian

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
