defmodule HomeDashWeb.Cards do
  @moduledoc """
  LiveComponent to displays Cards.

  Subscribes to providers that are passed in as `providers`.
  Initial cards can be passed in with `cards`.

  ## Example

    <.live_component
      module={HomeDashWeb.Cards}
      providers={[HomeDash.Providers.Welcome]}
      id="first"
    />
  """

  use Phoenix.LiveComponent

  # WARNING: not enforced :sob:
  attr :providers, :list, default: [], required: false
  attr :cards, :list, default: [], required: false
  attr :class, :string, required: false
  attr :card_class, :string, required: false

  @impl true
  def mount(socket) do
    {:ok, assign_defaults(socket)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> update_id(assigns)
      |> add_cards(assigns)
      |> delete_cards(assigns)
      |> update_providers(assigns)

    {:ok, socket}
  end

  def render_card(%{card: card} = assigns) do
    card.card_component.render(assigns)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-6 lg:grid-cols-8 xl:grid-cols-12 gap-x-6 gap-y-10 justify-items-center",
      @class
    ]}>
      <.render_card :for={card <- @display_cards} card={card} class={@card_class} />
    </div>
    """
  end

  defp assign_defaults(socket) do
    socket
    |> assign(:cards, %{})
    |> assign(:display_cards, [])
    |> assign(:providers, [])
    |> assign(:class, nil)
    |> assign(:card_class, nil)
  end

  defp add_cards(socket, %{add_cards: new_cards}) do
    new_cards = new_cards |> List.wrap() |> Enum.map(&{&1.id, &1}) |> Map.new()

    cards_map = Map.merge(socket.assigns.cards, new_cards)

    display_cards = cards_map |> Map.values() |> sort_my_cards()

    socket
    |> assign(:cards, cards_map)
    |> assign(:display_cards, display_cards)
  end

  defp add_cards(socket, _assigns), do: socket

  defp delete_cards(socket, %{delete_cards: removed_cards}) do
    removed_cards_ids =
      removed_cards
      |> List.wrap()
      |> Enum.map(fn
        id when is_binary(id) -> id
        %{id: id} -> id
      end)

    cards_map = Map.drop(socket.assigns.cards, removed_cards_ids)

    display_cards = cards_map |> Map.values() |> sort_my_cards()

    socket
    |> assign(:cards, cards_map)
    |> assign(:display_cards, display_cards)
  end

  defp delete_cards(socket, _assigns), do: socket

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
