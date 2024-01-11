defmodule HomeDashWeb.CardsLive do
  @moduledoc """
  A LiveView that wraps HomeDashWeb.Cards

  The providers for each action can be configured. E.g.
  ```
  config :home_dash, actions: [welcome: [HomeDash.Providers.Welcome]]
  ```

  ```
  live "/cards", CardsLive, :welcome
  ```

  """
  use HomeDashWeb, :live_view

  import HomeDash.Provider, only: [handle_info_home_dash: 0]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:providers, HomeDash.Config.provider(socket.assigns.live_action))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={HomeDashWeb.Cards} providers={@providers} id="first" />
    """
  end

  @impl true
  handle_info_home_dash()
end
