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
  def handle_info({:home_dash, :card, cards, component_id}, socket) do
    send_update(HomeDashWeb.Cards, id: component_id, cards: cards)

    {:noreply, socket}
  end

  def handle_info({:home_dash, :delete, _params}, socket) do
    {:noreply, socket}
  end
end
