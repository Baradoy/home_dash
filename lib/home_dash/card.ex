defmodule HomeDash.Card do
  @enforce_keys [:card_component, :id]
  defstruct [:card_component, :id, order: 0, data: %{}]
end
