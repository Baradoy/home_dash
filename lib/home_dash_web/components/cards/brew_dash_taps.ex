defmodule HomeDashWeb.Cards.BrewDashTaps do
  use HomeDashWeb, :html
  import HomeDashWeb.BrewDashCommon

  attr :card, HomeDash.Card, required: true
  attr :class, :string, required: false

  def render(assigns) do
    brew = assigns.card.data

    assigns =
      assigns
      |> assign(:image_url, Map.get(brew, "image_url"))
      |> assign_new(:tap_number, fn -> Map.get(brew, "tap_number") end)
      |> assign_new(:status_badge, fn -> Map.get(brew, "status_badge") end)
      |> assign_new(:status_badge_present, fn
        %{tap_number: tn, status_badge: "ON TAP"} when not is_nil(tn) -> true
        _ -> false
      end)
      |> assign(:is_gf, Map.get(brew, "is_gf"))
      |> assign(:full_name, Map.get(brew, "full_name"))
      |> assign(:abv, Map.get(brew, "abv"))

    ~H"""
    <div class={[
      "flex flex-col bg-white drop-shadow rounded-md col-span-3 relative rounded overflow-hidden shadow-lg max-w-98",
      "dark:bg-muted-gray",
      @class
    ]}>
      <div class="overflow-y-auto">
        <img class="h-96 w-full object-cover" src={@image_url} alt="Recipe Picture" />
      </div>

      <.floating_pill :if={@status_badge_present} align={:left}>
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

      <div class="px-6 py-4">
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
