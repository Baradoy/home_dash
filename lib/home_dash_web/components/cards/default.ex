defmodule HomeDashWeb.Cards.Default do
  use Phoenix.LiveComponent

  attr :card, HomeDash.Card, required: true

  def render(assigns) do
    assigns =
      assigns
      |> assign(:title, Map.get(assigns.card.data, :title, "Default Title"))
      |> assign(:message, Map.get(assigns.card.data, :message, "This is a default welcome card"))
      |> assign(:tags, Map.get(assigns.card.data, :tags, []))

    ~H"""
    <div class="max-w-sm rounded overflow-hidden shadow-lg">
      <img class="w-full" src="/img/card-top.jpg" alt={@title} />
      <div class="px-6 py-4">
        <div class="font-bold text-xl mb-2 text-purple-700"><%= @title %></div>
        <p class="text-gray-700 text-base">
          <%= @message %>
        </p>
        <p>
          <button phx-click="add_new_default_card" phx-target={@myself} type="button">
            Add new card
          </button>
        </p>
      </div>
      <div :for={tag <- @tags} class="px-6 pt-4 pb-2">
        <span class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2">
          <%= tag %>
        </span>
      </div>
    </div>
    """
  end

  def handle_event("add_new_default_card", _params, socket) do
    card2 = %HomeDash.Card{
      card_component: HomeDashWeb.Cards.Default,
      id: 4,
      order: 1,
      data: %{title: "My New Card"}
    }

    HomeDash.WelcomeCardProvider.push_card(card2)

    {:noreply, socket}
  end
end
