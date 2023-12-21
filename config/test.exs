import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :home_dash, HomeDashWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rgDQh+DtRszkk8hK4fMjB9sD8c0QDGYtcexgOEUtb1gh78hP5WreQfKnhBqqNiwN",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
