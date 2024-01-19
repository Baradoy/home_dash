defmodule HomeDash.Providers.Welcome do
  use HomeDash.Provider

  @impl true
  def handle_cards(:init, _opts) do
    {:ok,
     [
       %HomeDash.Card{
         namespace: __MODULE__,
         card_component: HomeDashWeb.Cards.Default,
         id: UUID.uuid4(),
         order: 1,
         data: %{title: "My First Card"}
       },
       %HomeDash.Card{
         namespace: __MODULE__,
         card_component: HomeDashWeb.Cards.Default,
         id: UUID.uuid4(),
         order: 2,
         data: %{title: "My Second Card"}
       }
     ]}
  end

  def handle_event("add_new_default_card", _params, _card) do
    push_cards(%HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 4,
      data: %{title: "My New Card"}
    })

    :ok
  end
end
