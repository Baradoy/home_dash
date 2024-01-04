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

  def subscribe(client_pid, server_pid) do
    GenServer.cast(server_pid, {:subscribe, client_pid})
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
  def handle_cast({:subscribe, pid}, state) do
    state = Map.put(state, :subscriptions, [pid | state.subscriptions])
    {:noreply, state, {:continue, {:subscribe, pid}}}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, state) do
    state = Map.put(state, :subscriptions, List.delete(state.subscriptions, pid))
    {:noreply, state} |> dbg
  end

  @impl true
  def handle_continue({:subscribe, client_pid}, state) do
    Enum.each(state.cards, fn card ->
      send(client_pid, {:home_dash, :card, card})
    end)

    Process.link(client_pid)

    {:noreply, state}
  end

  def handle_continue({:push_card, card}, state) do
    Enum.each(state.subscriptions, fn pid ->
      send(pid, {:home_dash, :card, card})
    end)

    {:noreply, state}
  end
end
