defmodule HomeDashWeb.Cards.BrewDashTaps do
  use HomeDashWeb, :html

  alias HomeDashWeb.Cards.Default

  attr :card, HomeDash.Card, required: true

  def render(assigns) do
    brew = assigns.card.data

    assigns =
      assigns
      |> assign(:image_url, Map.get(brew, "image_url"))
      |> assign(:abv, Map.get(brew, "abv"))
      |> assign_new(:tap_number, fn -> Map.get(brew, "tap_number") end)
      |> assign_new(:status_badge, fn -> Map.get(brew, "status_badge") end)
      |> assign_new(:status_badge_present, fn
        %{tap_number: tn, status_badge: "ON TAP"} when not is_nil(tn) -> true
        _ -> false
      end)
      |> assign_new(:message, fn
        %{abv: :unknown} -> "ABV: -"
        %{abv: abv} -> "ABV: #{abv}%"
      end)
      |> assign(:is_gf, Map.get(brew, "is_gf"))
      |> assign(:full_name, Map.get(brew, "full_name"))

    ~H"""
    <Default.render card={@card} title={@full_name} message={@message}>
      <:image>
        <img class="h-96 w-full object-cover" src={@image_url} alt="Recipe Picture" />
      </:image>

      <:floating_pill :if={@status_badge_present} align={:left}>
        <%= @tap_number %>
      </:floating_pill>

      <:floating_pill align={:right}>
        <%= @status_badge %>
      </:floating_pill>

      <:floating_pill
        :if={@is_gf}
        align={:right}
        class="mt-10 text-white dark:text-black bg-slate-400 dark:bg-white"
      >
        GF
      </:floating_pill>
    </Default.render>
    """
  end
end
