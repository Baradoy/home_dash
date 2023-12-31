defmodule HomeDash.Providers.BrewDashTaps do
  use GenServer

  @behaviour HomeDash.Provider

  @namespace :brew_dash

  # API

  @impl true
  def subscribe(_otps, name \\ __MODULE__) do
    GenServer.cast(name, {:subscribe, self()})
  end

  @impl true
  def push_card(card, name \\ __MODULE__) when is_struct(card, HomeDash.Card) do
    GenServer.cast(name, {:push_card, card})
  end

  @impl true
  def start_link(opts) when is_list(opts) do
    Keyword.fetch!(opts, :taps_url)
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
  def init(state) do
    {:ok, pid} = HomeDash.CardServer.start_link(@namespace)

    state = state |> Keyword.put(:server_pid, pid) |> Keyword.put(:taps, %{})

    {:ok, state, {:continue, :initial_cards}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    HomeDash.CardServer.subscribe(pid, Keyword.fetch!(state, :server_pid))
    {:noreply, state}
  end

  def handle_cast({:push_card, card}, state) do
    HomeDash.CardServer.push_card(card, Keyword.fetch!(state, :server_pid))
    {:noreply, state}
  end

  @impl true
  def handle_continue(:initial_cards, state) do
    {:noreply, state |> fetch_taps() |> schedule_polling()}
  end

  @impl true
  def handle_event(_event_name, _params, _card) do
    :ok
  end

  @impl true
  def handle_info(:poll_taps, state) do
    {:noreply, state |> fetch_taps() |> schedule_polling()}
  end

  defp fetch_taps(state) do
    pid = Keyword.fetch!(state, :server_pid)

    current_taps =
      state
      |> Keyword.fetch!(:taps_url)
      |> Req.get!()
      |> Map.get(:body)
      |> Map.get("taps")
      |> Enum.with_index()
      |> Enum.map(&tap_to_card/1)
      |> Map.new()

    Enum.each(current_taps, fn {_id, card} ->
      GenServer.cast(pid, {:push_card, card})
    end)

    # TODO: Send cleanup for removed taps

    Keyword.put(state, :taps, current_taps)
  end

  defp tap_to_card({tap, index}) do
    card = %HomeDash.Card{
      namespace: __MODULE__,
      card_component: HomeDashWeb.Cards.BrewDashTaps,
      id: to_string(tap["id"]),
      order: index,
      data: tap
    }

    {card.id, card}
  end

  defp schedule_polling(state) do
    polling_interval = Keyword.get(state, :polling_interval, 60 * 1000)

    Process.send_after(self(), :poll_taps, polling_interval)

    state
  end
end
