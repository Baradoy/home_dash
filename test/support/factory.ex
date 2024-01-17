defmodule HomeDash.Factory do
  use ExMachina
  alias HomeDash.Card

  def card_factory do
    %Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 1,
      data: %{title: "My Test Card"}
    }
  end
end
