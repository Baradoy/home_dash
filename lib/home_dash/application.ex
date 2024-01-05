defmodule HomeDash.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # HomeDashWeb.Telemetry,
        # {DNSCluster, query: Application.get_env(:home_dash, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: HomeDash.PubSub}
        # Start a worker by calling: HomeDash.Worker.start_link(arg)
        # {HomeDash.Worker, arg},
        # Start to serve requests, typically the last entry
        # HomeDashWeb.Endpoint
      ] ++ home_dash_servers()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeDash.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HomeDashWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def home_dash_servers() do
    Application.get_env(:home_dash, :servers, [HomeDash.WelcomeCardProvider])
  end
end
