defmodule HomeDash.Card do
  @enforce_keys [:namespace, :card_component, :id]
  defstruct [:namespace, :card_component, :id, order: 0, data: %{}]
end
