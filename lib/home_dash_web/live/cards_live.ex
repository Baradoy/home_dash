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
        :for={card <- @home_dash_cards}
        module={card.card_component}
        id={card.id}
        card={card}
      />
    </div>
    """
  end

  defp assign_defaults(socket) do
    # TODO this can probably be a stream
    assign(socket, :home_dash_cards, [])
  end

  @impl true
  def handle_info({:home_dash, :initial, cards}, socket) do
    {:noreply, assign(socket, :home_dash_cards, sort_my_cards(cards))}
  end

  @impl true
  def handle_info({:home_dash, :new, card}, socket) do
    {:noreply, assign(socket, :home_dash_cards, sort_my_cards([card | socket.assigns.home_dash_cards]))}
  end

  def handle_info({:home_dash, :delete, _params}, socket) do
    {:noreply, socket}
  end

  def handle_info({:home_dash, :update, _params}, socket) do
    {:noreply, socket}
  end

  defp sort_my_cards(cards) do
    Enum.sort(cards, &(&1.order <= &2.order))
  end
end
