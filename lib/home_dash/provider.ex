defmodule HomeDash.Provider do
  @callback subscribe(keyword(), pid(), term()) :: :ok
  @callback push_card(HomeDash.Card.t(), pid()) :: :ok
  @callback start_link(keyword()) :: GenServer.on_start()
  @callback handle_event(String.t(), map(), HomeDash.Card.t()) :: :ok
end
