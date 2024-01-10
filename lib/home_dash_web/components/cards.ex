defmodule HomeDashWeb.Cards do
  @moduledoc """
  LiveComponenet to displays Cards.

  Subscribes to providers that are passed in as `providers`.
  Initial cards can be passed in with `cards`.

  ## Example

    <.live_component
      module={HomeDashWeb.Cards}
      providers={@providers}
      id="first"
    />
  """

  use Phoenix.LiveComponent

  attr :providers, :list, required: true

  @impl true
  def mount(socket) do
    socket = socket |> assign_defaults()

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> update_id(assigns)
      |> update_cards(assigns)
      |> update_providers(assigns)

    {:ok, socket}
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
    |> assign(:cards, %{})
    |> assign(:display_cards, [])
    |> assign(:providers, [])
  end

  defp update_cards(socket, %{cards: new_cards}) do
    new_cards = new_cards |> List.wrap() |> Enum.map(&{&1.id, &1}) |> Map.new()

    cards_map = Map.merge(socket.assigns.cards, new_cards)

    display_cards = cards_map |> Map.values() |> sort_my_cards()

    socket
    |> assign(:cards, cards_map)
    |> assign(:display_cards, display_cards)
  end

  defp update_cards(socket, _assigns), do: socket

  defp sort_my_cards(cards) do
    Enum.sort(cards, &(&1.order <= &2.order))
  end

  defp update_providers(socket, %{providers: providers}) do
    if connected?(socket) do
      Enum.each(providers, fn {module, opts} ->
        apply(module, :subscribe, [
          opts,
          Keyword.get(opts, :server_name, module),
          socket.assigns.id
        ])
      end)

      new_providers = socket.assigns.providers |> Enum.concat(providers) |> Enum.uniq()

      assign(socket, :providers, new_providers)
    else
      socket
    end
  end

  defp update_providers(socket, _assigns), do: socket

  defp update_id(socket, %{id: id}), do: assign(socket, :id, id)

  defp update_id(socket, _assigns), do: socket
end
