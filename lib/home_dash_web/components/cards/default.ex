defmodule HomeDashWeb.Cards.Default do
  use Phoenix.LiveComponent
  import HomeDashWeb.CardsCommon

  attr :card, HomeDash.Card, required: true
  attr :title, :string, required: false
  slot :inner_block, required: false

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> Map.get(assigns.card.data, :title, "Default Title") end)
      |> assign(:message, Map.get(assigns.card.data, :message, "This is a default welcome card"))
      |> assign(:tags, Map.get(assigns.card.data, :tags, []))
      |> assign(:img_uri, Map.get(assigns.card.data, :img_uri, nil))
      |> assign_new(:class, fn -> "col-span-2" end)

    ~H"""
    <div class={"#{base_card_styles()} #{@class}"}>
      <img :if={@img_uri} class="w-full" src={@img_uri} alt={@title} />
      <div class="px-6 py-4">
        <div class="font-bold text-xl mb-2 text-purple-700"><%= @title %></div>
        <p class="text-gray-700 text-base">
          <%= if Enum.empty?(@inner_block), do: @message,  else: render_slot(@inner_block) %>
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

  def handle_event(event_name, params, socket) do
    apply(
      socket.assigns.card.namespace,
      :handle_event,
      [event_name, params, socket.assigns.card]
    )

    {:noreply, socket}
  end
end
