defmodule HomeDashWeb.CardsLive do
  use HomeDashWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: HomeDash.WelcomeCardProvider.subscribe()

    {:ok, assign_defaults(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="full-w flex grid-cols-4">
      <.live_component
        :for={card <- @display_cards}
        module={card.card_component}
        id={card.id}
        card={card}
      />
    </div>
    """
  end

  defp assign_defaults(socket) do
    socket
    |> assign(:home_dash_cards, %{})
    |> assign(:display_cards, [])
  end

  @impl true
  def handle_info({:home_dash, :card, card}, socket) when is_struct(card, HomeDash.Card) do
    home_dash_cards = Map.put(socket.assigns.home_dash_cards, card.id, card)

    display_cards = home_dash_cards |> Map.values() |> sort_my_cards()

    {:noreply,
     socket
     |> assign(:home_dash_cards, home_dash_cards)
     |> assign(:display_cards, display_cards)}
  end

  def handle_info({:home_dash, :delete, _params}, socket) do
    {:noreply, socket}
  end

  defp sort_my_cards(cards) do
    Enum.sort(cards, &(&1.order <= &2.order))
  end
end
