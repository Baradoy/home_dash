defmodule HomeDashWeb.Cards.Default do
  # credo:disable-for-this-file Credo.Check.Refactor.Apply
  use HomeDashWeb, :html

  import HomeDashWeb.CardComponents

  attr :card, HomeDash.Card, required: true
  attr :title, :string, required: false
  attr :message, :string, required: false
  attr :img_uri, :string, required: false
  attr :class, :string, required: false

  slot :inner_block, required: false
  slot :image, required: false

  slot :floating_pill, doc: "A floating Pill" do
    attr :align, :atom, required: true, values: [:right, :left]
    attr :background, :string, required: false
    attr :class, :string, required: false
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> Map.get(assigns.card.data, :title) end)
      |> assign_new(:message, fn -> Map.get(assigns.card.data, :message) end)
      |> assign_new(:img_uri, fn -> Map.get(assigns.card.data, :img_uri, nil) end)
      |> assign_new(:class, fn -> "" end)
      |> assign(:tags, Map.get(assigns.card.data, :tags, []))

    ~H"""
    <div class={[
      "flex flex-col drop-shadow rounded-md col-span-3 relative rounded overflow-hidden shadow-lg w-full",
      "bg-white",
      "dark:bg-zinc-700",
      @class
    ]}>
      <div :if={@img_uri} class="overflow-y-auto">
        <img class="h-96 w-full object-cover" src={@img_uri} />
      </div>
      <div :if={@image} class="overflow-y-auto">
        <%= render_slot(@image) %>
      </div>

      <%= for pill <- @floating_pill do %>
        <.floating_pill align={pill.align} class={pill[:class]}>
          <%= render_slot(pill) %>
        </.floating_pill>
      <% end %>

      <div class="px-6 py-4">
        <div :if={@title} class="font-bold text-xl mb-2">
          <%= @title %>
        </div>

        <p :if={@message} class="text-gray-400 text-base">
          <%= @message %>
        </p>

        <%= render_slot(@inner_block) %>

        <div :for={tag <- @tags} class="px-6 pt-4 pb-2">
          <span class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2">
            <%= tag %>
          </span>
        </div>
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
