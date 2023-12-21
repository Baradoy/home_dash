defmodule HomeDash.WelcomeCardProvider do
  use GenServer

  def subscribe() do
    pid = Process.whereis(HomeDash.WelcomeCardProvider)
    Process.link(pid)
    GenServer.cast(pid, {:subscribe, self()})
  end

  def start_link(state) when is_list(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, {[], state}}
  end

  def push_card(card , pid \\ __MODULE__) do
    GenServer.cast(pid, {:push_card, card})
  end

  @impl true
  def handle_cast({:push_card, card}, {subscriptions, state}) do
    {:noreply, {subscriptions, [card | state]}, {:continue, {:push_card, card}}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, {subscriptions, state}) do
    {:noreply, {[pid | subscriptions], state}, {:continue, {:subscribe, pid}}}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, {subscriptions, state}) do
    {:noreply, {List.delete(subscriptions, pid), state}} |> dbg
  end

  @impl true
  def handle_continue({:subscribe, pid}, {subscriptions, state}) do
    send(pid, {:home_dash, :initial, state})

    {:noreply, {subscriptions, state}}
  end

  def handle_continue({:push_card, card}, {subscriptions, state}) do
    Enum.each(subscriptions, fn pid ->
      send(pid, {:home_dash, :new, card})
    end)

    {:noreply, {subscriptions, state}}
  end
end
