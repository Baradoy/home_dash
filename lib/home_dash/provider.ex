defmodule HomeDash.Provider do
  @moduledoc """
  Defines a homedash provider.

  A homedash provider is responsible for sending cards and card updates to subscribers.

  `use HomeDash.Provider`

  ### Overridable

  ```
  def handle_cards(msg, opts) do
    {:ok, fetch_cards()}
  end

  """
  require Logger

  alias HomeDash.Provider.State

  @type handle_cards_response() ::
          {:ok, State.cards()}
          | {:new, State.cards()}
          | {:delete, State.cards() | list(String.t())}
          | {:error, any()}

  @callback subscribe(keyword(), pid(), term()) :: :ok
  @callback push_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback set_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback remove_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback start_link(keyword()) :: GenServer.on_start()
  @callback handle_cards(term(), State.opts()) :: handle_cards_response()

  @optional_callbacks handle_cards: 2

  defmacro __using__(provider_opts) do
    polling_interval = Keyword.get(provider_opts, :polling_interval)

    quote do
      use GenServer

      alias HomeDash.Provider
      alias HomeDash.Provider.State

      @behaviour unquote(__MODULE__)

      @impl true
      def subscribe(_otps, name, id), do: GenServer.cast(name, {:subscribe, self(), id})

      @impl true
      def push_cards(cards, pid \\ __MODULE__),
        do: Provider.__handle_cards__({:push_cards, cards}, pid)

      @impl true
      def set_cards(cards, pid \\ __MODULE__),
        do: Provider.__handle_cards__({:set_cards, cards}, pid)

      @impl true
      def remove_cards(cards, pid \\ __MODULE__),
        do: Provider.__handle_cards__({:remove_cards, cards}, pid)

      @impl true
      def start_link(opts) do
        name = Keyword.get(opts, :server_name, __MODULE__)
        GenServer.start_link(__MODULE__, opts, name: name)
      end

      def child_spec(opts) do
        %{
          id: Keyword.get(opts, :server_name, __MODULE__),
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      # Server

      @impl true
      def init(opts) do
        Process.flag(:trap_exit, true)

        state = %{opts: opts, cards: %{}, subscriptions: []}

        {:ok, state, {:continue, {:handle_cards, :home_dash_init}}}
      end

      @impl true
      def handle_cast({:subscribe, pid, component_id}, state) do
        state = State.add_subscription(state, pid, component_id)
        {:noreply, state, {:continue, {:subscribe, {pid, component_id}}}}
      end

      def handle_cast({:push_cards, new_cards}, state) do
        {state, new_cards, []} = State.add_cards(state, new_cards)

        {:noreply, state, {:continue, {:broadcast_cards, new_cards, []}}}
      end

      def handle_cast({:set_cards, new_cards}, state) do
        {state, new_cards, removed_cards} = State.set_cards(state, new_cards)

        {:noreply, state, {:continue, {:broadcast_cards, new_cards, removed_cards}}}
      end

      def handle_cast({:remove_cards, removed_cards}, state) do
        {state, [], removed_cards} = State.remove_cards(state, removed_cards)

        {:noreply, state, {:continue, {:broadcast_cards, [], removed_cards}}}
      end

      @impl true
      def handle_info({:EXIT, dead_pid, _reason}, state) do
        state = State.remove_subscription(state, dead_pid)

        {:noreply, state}
      end

      def handle_info(:home_dash_poll, state) do
        {:noreply, state, {:continue, {:handle_cards, :home_dash_poll}}}
      end

      def handle_info(message, state) do
        {:noreply, state, {:continue, {:handle_cards, message}}}
      end

      # Only poll on poll or init call, since this gets called for all handle_cards/2 calls
      if is_integer(unquote(polling_interval)) do
        def poll(msg) when msg == :home_dash_poll or msg == :home_dash_init do
          Process.send_after(self(), :home_dash_poll, unquote(polling_interval))
        end
      end

      def poll(_msg), do: :ok

      @impl true
      def handle_continue({:handle_cards, message}, state) do
        message
        |> public_message_name()
        |> handle_cards(state.opts)
        |> Provider.__handle_cards__(self())

        poll(message)
        {:noreply, state}
      end

      def handle_continue({:subscribe, {client_pid, component_id}}, state) do
        send(client_pid, {:home_dash, :add, Map.values(state.cards), component_id})

        Process.link(client_pid)

        {:noreply, state}
      end

      def handle_continue({:broadcast_cards, cards, removed_cards}, state) do
        Enum.each(state.subscriptions, fn {pid, component_id} ->
          send(pid, {:home_dash, :add, cards, component_id})
        end)

        Enum.each(state.subscriptions, fn {pid, component_id} ->
          send(pid, {:home_dash, :delete, removed_cards, component_id})
        end)

        {:noreply, state}
      end

      def public_message_name(:home_dash_init), do: :init
      def public_message_name(:home_dash_poll), do: :poll
      def public_message_name(msg), do: msg

      def handle_cards(_message, _opts), do: {:ok, []}

      defoverridable handle_cards: 2
    end
  end

  defmacro handle_info_home_dash do
    quote do
      def handle_info({:home_dash, :add, cards, component_id}, socket) do
        send_update(HomeDashWeb.Cards, id: component_id, add_cards: cards)

        {:noreply, socket}
      end

      def handle_info({:home_dash, :delete, cards, component_id}, socket) do
        send_update(HomeDashWeb.Cards, id: component_id, delete_cards: cards)

        {:noreply, socket}
      end
    end
  end

  def __handle_cards__({:ok, cards}, pid), do: __handle_cards__({:set_cards, cards}, pid)

  def __handle_cards__({:error, reason}, _pid),
    do: Logger.warning("handle_cards failed for #{__MODULE__}:#{self()} '#{inspect(reason)}'")

  def __handle_cards__({msg, cards}, pid), do: GenServer.cast(pid, {msg, List.wrap(cards)})
end
