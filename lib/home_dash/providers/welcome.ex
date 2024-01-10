defmodule HomeDash.Providers.Welcome do
  use GenServer

  @behaviour HomeDash.Provider

  @namespace :welcome

  # API

  @impl true
  def subscribe(_otps, name, id) do
    GenServer.cast(name, {:subscribe, self(), id})
  end

  @impl true
  def push_card(card, name \\ __MODULE__) when is_struct(card, HomeDash.Card) do
    GenServer.cast(name, {:push_card, card})
  end

  @impl true
  def start_link(opts) do
    name = Keyword.get(opts, :server_name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # Server

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :server_name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(_state) do
    {:ok, pid} = HomeDash.CardServer.start_link(@namespace)
    {:ok, %{server_pid: pid}, {:continue, :initial_cards}}
  end

  @impl true
  def handle_cast({:subscribe, pid, cid}, state) do
    HomeDash.CardServer.subscribe(pid, cid, state.server_pid)
    {:noreply, state}
  end

  def handle_cast({:push_card, card}, state) do
    HomeDash.CardServer.push_card(card, state.server_pid)
    {:noreply, state}
  end

  @impl true
  def handle_continue(:initial_cards, state) do
    push_card(%HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 1,
      data: %{title: "My First Card"}
    })

    push_card(%HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 2,
      data: %{title: "My Second Card"}
    })

    {:noreply, state}
  end

  @impl true
  def handle_event("add_new_default_card", _params, _card) do
    push_card(%HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.Default,
      id: UUID.uuid4(),
      order: 4,
      data: %{title: "My New Card"}
    })

    :ok
  end
end
