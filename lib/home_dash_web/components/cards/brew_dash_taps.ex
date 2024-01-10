defmodule HomeDashWeb.Cards.BrewDashTaps do
  use Phoenix.LiveComponent

  import HomeDashWeb.CardsCommon
  import HomeDashWeb.BrewDashCommon

  attr :card, HomeDash.Card, required: true

  def render(assigns) do
    assigns =
      assigns
      |> assign(:image_url, Map.get(assigns.card.data, "image_url"))
      |> assign(:tap_number, Map.get(assigns.card.data, "tap_number"))
      |> assign(:status_badge, Map.get(assigns.card.data, "status_badge"))
      |> assign(:is_gf, Map.get(assigns.card.data, "is_gf"))
      |> assign(:full_name, Map.get(assigns.card.data, "full_name"))
      |> assign(:abv, Map.get(assigns.card.data, "abv"))

    ~H"""
    <div class={"#{base_card_styles()} col-span-3 relative max-w-98 rounded overflow-hidden shadow-lg"}>
      <div class="overflow-y-auto">
        <img class="h-96 w-98 object-cover" src={@image_url} alt="Recipe Picture" />
      </div>

      <.floating_pill :if={@tap_number} align={:left}>
        <%= @tap_number %>
      </.floating_pill>

      <.floating_pill align={:right}>
        <%= @status_badge %>
      </.floating_pill>

      <.floating_pill
        :if={@is_gf}
        align={:right}
        class="mt-10 px-0 pt-0 pb-0 dark:bg-slate-900 bg-transparent dark:rounded-full"
      >
        <.icon_gf tip="Gluten Free" class="dark:fill-slate-100" />
      </.floating_pill>

      <div class="px-6 py-4 dark:bg-muted-gray">
        <div class="font-bold text-xl mb-2">
          <%= @full_name %>
        </div>
        <p class="text-gray-400 text-base">
          <%= if @abv != :unknown do %>
            ABV: <%= @abv %>%
          <% else %>
            ABV: -
          <% end %>
        </p>
      </div>
    </div>
    """
  end
end
