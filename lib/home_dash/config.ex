defmodule HomeDash.Config do
  @moduledoc """
  Easy access to HolmeDash config

  ## Examples

    # The default welcome card prodiver. This is the Hello World of HomeDash
    config :home_dash, servers: [{HomeDash.Providers.Welcome, []}]

    # Two actions with different providers
    config :home_dash,
        actions: [
          welcome: [HomeDash.Providers.Welcome],
          brewdash: [HomeDash.Providers.Welcome, HomeDash.Providers.BrewDashTaps]
        ]

    # Two different BrewDash providers, each with a different configuration.
    config :home_dash,
      actions: [
        downstairs: [
          {HomeDash.Providers.BrewDashTaps, [
            server_name: HomeDash.Providers.BrewDashTaps.Upstairs,
            taps_url: "https://example.com/api/taps"
          ]}
        ]
        upstairs: [
          {HomeDash.Providers.BrewDashTaps, [
            server_name: HomeDash.Providers.BrewDashTaps.Downstairs,
            taps_url: "https://other.example.com/api/taps"
          ]}
        ]
      ]

  """

  @default_providers [{HomeDash.Providers.Welcome, []}]

  @doc """
  Get the servers from the config.

  Falling back to the providers defined in `:actions` and then eventually to the @default_providers module.
  """
  def servers do
    Application.get_env(:home_dash, :servers, all_providers())
  end

  @doc """
  Gets the provider for the action.

  If the action is not defined, fall back to the configured provider servers.
  """
  def provider(action) when is_atom(action) do
    :home_dash
    |> Application.get_env(:actions, [])
    |> Keyword.get(action, servers())
    |> Enum.map(&format/1)
  end

  @doc """
  List all card providers configured under actions
  """
  def all_providers() do
    case Application.get_env(:home_dash, :actions, []) do
      [] ->
        @default_providers

      actions ->
        actions |> Keyword.values() |> Enum.concat() |> Enum.map(&format/1) |> Enum.uniq()
    end
  end

  defp format({module, opts}) when is_atom(module) and is_list(opts),
    do: {module, Keyword.put_new(opts, :server_name, module)}

  defp format(module) when is_atom(module), do: {module, [server_name: module]}
end
