defmodule HomeDash.Provider.State do
  @moduledoc """
  State handling for a Provider.

  State includes a list of cards and subscriptions.

  Subscriptions inculde the process id and the component component id for message routing purposes.
  """

  @type opts() :: term()
  @type component_id() :: String.t()
  @type subscription() :: {pid(), component_id()}
  @type t() :: %__MODULE__{
          opts: opts(),
          cards: %{String.t() => HomeDash.Card.t()},
          subscriptions: [subscription()]
        }

  @type cards() :: list(HomeDash.Card.t())
  @type cards_response() :: {t(), cards(), cards()}

  defstruct opts: [], cards: %{}, subscriptions: []

  @spec add_cards(t(), cards()) :: cards_response()
  def add_cards(state, new_cards) do
    new_cards_map = new_cards |> Enum.map(&{&1.id, &1}) |> Map.new()
    cards = Map.merge(state.cards, new_cards_map)
    state = Map.put(state, :cards, cards)

    {state, new_cards, []}
  end

  @spec new(opts()) :: t()
  def new(opts), do: %__MODULE__{opts: opts}

  @spec set_cards(t(), cards()) :: cards_response()
  def set_cards(state, new_cards) do
    cards = Map.new(new_cards, &{&1.id, &1})
    removed_cards = state.cards |> Map.drop(Map.keys(cards)) |> Map.values()

    state = Map.put(state, :cards, cards)

    {state, new_cards, removed_cards}
  end

  @spec remove_cards(t(), cards()) :: cards_response()
  def remove_cards(state, removed_cards) do
    remove_card_ids =
      removed_cards
      |> Enum.map(fn
        id when is_binary(id) -> id
        %{id: id} -> id
      end)

    cards = Map.drop(state.cards, remove_card_ids)

    state = Map.put(state, :cards, cards)

    {state, [], removed_cards}
  end

  @spec add_subscription(t(), pid(), component_id()) :: t()
  def add_subscription(state, pid, component_id) when is_pid(pid) and is_binary(component_id) do
    Map.put(state, :subscriptions, [{pid, component_id} | state.subscriptions])
  end

  @spec remove_subscription(t(), pid()) :: t()
  def remove_subscription(state, remove_pid) do
    subscriptions = Enum.reject(state.subscriptions, fn {pid, _cid} -> pid == remove_pid end)

    Map.put(state, :subscriptions, subscriptions)
  end
end
