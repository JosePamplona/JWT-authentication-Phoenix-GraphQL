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
  metadata: [:request_id]

config :jay_auth, JayAuth.Guardian,
  issuer: "Jay-Auth",
  secret_key: :crypto.strong_rand_bytes(30) |> Base.url_encode64 |> binary_part(0, 30),
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  token_ttl: %{
    "access" => {5, :minutes},
    "refresh" => {7, :days}
  },
  allowed_drift: 2000,
  verify_issuer: true,
  serializer: JayAuth.Guardian

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
