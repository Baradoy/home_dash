defmodule HomeDashWeb.CardsLive do
  use HomeDashWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_defaults()
     |> assign_card_providers()
     |> subscribe_to_card_providers()}
  end

  defp subscribe_to_card_providers(socket) do
    if connected?(socket) do
      Enum.each(socket.assigns.card_providers, fn {module, opts} ->
        apply(module, :subscribe, [opts])
      end)
    end

    socket
  end

  defp assign_card_providers(socket) do
    card_providers =
      :home_dash
      |> Application.get_env(:actions, [])
      |> Keyword.get(socket.assigns.live_action, HomeDash.Application.home_dash_servers())
      |> Enum.map(fn
        {module, opts} when is_atom(module) -> {module, opts}
        module when is_atom(module) -> {module, []}
      end)

    assign(socket, :card_providers, card_providers)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-6 lg:grid-cols-8 xl:grid-cols-12 gap-x-6 gap-y-10 justify-items-center">
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
    |> assign(:card_providers, [])
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
