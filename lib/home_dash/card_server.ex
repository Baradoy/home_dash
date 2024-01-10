defmodule HomeDash.CardServer do
  @moduledoc """
    A server to keep card state and send state to subscribers.

    Implementation note:
      Card providers like WelcomeCardProvider interact with this service through the API and server PID.
      Another possible implementation would be to go the metaprogramming route.
  """

  use GenServer

  def start_link(namespace) when is_atom(namespace) do
    GenServer.start_link(__MODULE__, namespace)
  end

  def subscribe(client_pid, component_id, server_pid) do
    GenServer.cast(server_pid, {:subscribe, client_pid, component_id})
  end

  @impl true
  def init(namespace) do
    Process.flag(:trap_exit, true)
    state = %{namespace: namespace, cards: [], subscriptions: []}
    {:ok, state}
  end

  def push_card(card, pid) do
    GenServer.cast(pid, {:push_card, card})
  end

  @impl true
  def handle_cast({:push_card, card}, state) do
    state = Map.put(state, :cards, [card | state.cards])
    {:noreply, state, {:continue, {:push_card, card}}}
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

  def handle_continue({:push_card, card}, state) do
    Enum.each(state.subscriptions, fn {pid, component_id} ->
      send(pid, {:home_dash, :card, card, component_id})
    end)

    {:noreply, state}
  end
end
