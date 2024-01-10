defmodule HomeDashWeb.CardsCommon do
  use Phoenix.Component

  @base_card_styles "flex flex-col bg-white drop-shadow hover:drop-shadow-lg hover:opacity-70 rounded-md"
  def base_card_styles, do: @base_card_styles
end
