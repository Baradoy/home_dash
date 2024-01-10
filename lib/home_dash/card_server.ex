defmodule HomeDash.CardServer do
  @moduledoc """
    A server to keep card state and send state to subscribers.

    Implementation note:
      Card providers like WelcomeCardProvider interact with this service through the API and server PID.
      Another possible implementation would be to go the metaprogramming route.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def subscribe(client_pid, component_id, server_pid) do
    GenServer.cast(server_pid, {:subscribe, client_pid, component_id})
  end

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    state = %{cards: [], subscriptions: []}
    {:ok, state}
  end

  def push_cards(card, pid) do
    GenServer.cast(pid, {:push_cards, List.wrap(card)})
  end

  def delete_cards(card, pid) do
    GenServer.cast(pid, {:delete_cards, List.wrap(card)})
  end

  @impl true
  def handle_cast({:push_cards, new_cards}, state) do
    cards = new_cards |> Enum.concat(state.cards) |> Enum.uniq()
    state = Map.put(state, :cards, cards)
    {:noreply, state, {:continue, {:push_cards, new_cards}}}
  end

  @impl true
  def handle_cast({:subscribe, pid, component_id}, state) do
    state = Map.put(state, :subscriptions, [{pid, component_id} | state.subscriptions])
    {:noreply, state, {:continue, {:subscribe, {pid, component_id}}}}
  end

  @impl true
  def handle_info({:EXIT, dead_pid, _reason}, state) do
    subscriptions = Enum.reject(state.subscriptions, fn {pid, _cid} -> pid == dead_pid end)
    {:noreply, Map.put(state, :subscriptions, subscriptions)}
  end

  @impl true
  def handle_continue({:subscribe, {client_pid, component_id}}, state) do
    Enum.each(state.cards, fn card ->
      send(client_pid, {:home_dash, :card, card, component_id})
    end)

    Process.link(client_pid)

    {:noreply, state}
  end

  def handle_continue({:push_cards, cards}, state) do
    Enum.each(state.subscriptions, fn {pid, component_id} ->
      send(pid, {:home_dash, :card, cards, component_id})
    end)

    {:noreply, state}
  end

  def handle_continue({:delete_cards, cards}, state) do
    Enum.each(state.subscriptions, fn {pid, component_id} ->
      send(pid, {:home_dash, :delete, cards, component_id})
    end)

    {:noreply, state}
  end
end
