defmodule HomeDash.Factory do
  use ExMachina
  alias HomeDash.Card
  alias HomeDash.Provider.State

  def card_factory do
    %Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 1,
      data: %{title: "My Test Card"}
    }
  end

  def state_factory do
    %State{}
  end

  def with_cards(%State{} = state, cards) do
    cards_map = Map.new(cards, &{&1.id, &1})
    %{state | cards: cards_map}
  end
end
