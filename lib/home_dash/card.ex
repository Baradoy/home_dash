defmodule HomeDash.Card do

  @type t() :: %__MODULE__{
    namespace: atom(),
    card_component: atom(),
    id: String.t(),
    order: 0,
    data: map()
  }

  @enforce_keys [:namespace, :card_component, :id]
  defstruct [:namespace, :card_component, :id, order: 0, data: %{}]
end
