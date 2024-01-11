defmodule HomeDash.Providers.BrewDashTaps do
  use HomeDash.Provider, polling_interval: 60_000

  def handle_cards(opts) do
    current_taps =
      opts
      |> Keyword.fetch!(:taps_url)
      |> Req.get!()
      |> Map.get(:body)
      |> Map.get("taps")
      |> Enum.with_index()
      |> Enum.map(&tap_to_card/1)

    {:ok, current_taps}
  end

  defp tap_to_card({tap, index}) do
    %HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.BrewDashTaps,
      id: to_string(tap["id"]),
      order: index,
      data: tap
    }
  end
end
