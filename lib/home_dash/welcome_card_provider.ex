defmodule HomeDash.WelcomeCardProvider do
  use GenServer

  @namespace :welcome

  # API

  def subscribe(pid \\ __MODULE__) do
    GenServer.cast(pid, {:subscribe, self()})
  end

  def push_card(card, pid \\ __MODULE__) do
    GenServer.cast(pid, {:push_card, card})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # Server

  @impl true
  def init(_state) do
    {:ok, pid} = HomeDash.CardServer.start_link(@namespace)
    {:ok, %{server_pid: pid}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    HomeDash.CardServer.subscribe(pid, state.server_pid)
    {:noreply, state}
  end

  def handle_cast({:push_card, card}, state) do
    HomeDash.CardServer.push_card(card, state.server_pid)
    {:noreply, state}
  end
end
