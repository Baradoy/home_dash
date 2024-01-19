defmodule HomeDash.Provider do
  @moduledoc """
  Defines a homedash provider.

  A homedash provider is responsible for sending cards and card updates to subscribers.

  `use HomeDash.Provider`

  ### Overridable

  ```
  def handle_cards(opts) do
    {:ok, fetch_cards()}
  end

  """

  @type opts() :: term()
  @type component_id() :: String.t()
  @type subscription() :: {pid(), component_id()}
  @type state() :: %{
          opts: opts(),
          cards: %{String.t() => HomeDash.Card.t()},
          subscriptions: [subscription()]
        }
  @type handle_cards_response() ::
          {:ok, list(HomeDash.Card.t())}
          | {:new, list(HomeDash.Card.t())}
          | {:delete, list(HomeDash.Card.t() | String.t())}
          | {:error, any()}

  @callback subscribe(keyword(), pid(), term()) :: :ok
  @callback push_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback set_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback remove_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback start_link(keyword()) :: GenServer.on_start()
  @callback handle_cards(term(), opts()) :: handle_cards_response()

  @optional_callbacks handle_cards: 2

  defmacro __using__(provider_opts) do
    polling_interval = Keyword.get(provider_opts, :polling_interval)

    quote do
      use GenServer

      require Logger

      @behaviour unquote(__MODULE__)

      @impl true
      def subscribe(_otps, name, id) do
        GenServer.cast(name, {:subscribe, self(), id})
      end

      @impl true
      def push_cards(cards, pid \\ __MODULE__) do
        GenServer.cast(pid, {:push_cards, List.wrap(cards)})
      end

      @impl true
      def set_cards(cards, pid \\ __MODULE__) do
        GenServer.cast(pid, {:set_cards, List.wrap(cards)})
      end

      @impl true
      def remove_cards(cards, pid \\ __MODULE__) do
        GenServer.cast(pid, {:remove_cards, List.wrap(cards)})
      end

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
        state = Map.put(state, :subscriptions, [{pid, component_id} | state.subscriptions])
        {:noreply, state, {:continue, {:subscribe, {pid, component_id}}}}
      end

      def handle_cast({:push_cards, new_cards}, state) do
        new_cards_map = new_cards |> Enum.map(&{&1.id, &1}) |> Map.new()
        cards = Map.merge(state.cards, new_cards_map)
        state = Map.put(state, :cards, cards)
        {:noreply, state, {:continue, {:broadcast_cards, new_cards, []}}}
      end

      def handle_cast({:set_cards, new_cards}, state) do
        cards = new_cards |> Enum.map(&{&1.id, &1}) |> Map.new()
        removed_cards = state.cards |> Map.drop(Map.keys(cards)) |> Map.values()

        state = Map.put(state, :cards, cards)
        {:noreply, state, {:continue, {:broadcast_cards, new_cards, removed_cards}}}
      end

      def handle_cast({:remove_cards, removed_cards}, state) do
        remove_card_ids =
          removed_cards
          |> Enum.map(fn
            id when is_binary(id) -> id
            %{id: id} -> id
          end)

        cards = Map.drop(state.cards, remove_card_ids)

        state = Map.put(state, :cards, cards)
        {:noreply, state, {:continue, {:broadcast_cards, [], removed_cards}}}
      end

      @impl true
      def handle_info({:EXIT, dead_pid, _reason}, state) do
        subscriptions = Enum.reject(state.subscriptions, fn {pid, _cid} -> pid == dead_pid end)
        {:noreply, Map.put(state, :subscriptions, subscriptions)}
      end

      def handle_info(:home_dash_poll, state) do
        {:noreply, state, {:continue, {:handle_cards, :home_dash_poll}}}
      end

      def handle_info(message, state) do
        {:noreply, state, {:continue, {:handle_cards, message}}}
      end

      # Only poll on poll or init call, since this gets called for all handle_cards/2 calls
      def poll(msg) when msg == :home_dash_poll or msg == :home_dash_init do
        if is_integer(unquote(polling_interval)) do
          Process.send_after(self(), :home_dash_poll, unquote(polling_interval))
        end
      end

      def poll(_msg), do: :ok

      @impl true
      def handle_continue({:handle_cards, message}, state) do
        case message |> public_message_name() |> handle_cards(state.opts) do
          {:ok, cards} ->
            set_cards(cards, self())

          {:new, cards} ->
            push_cards(cards, self())

          {:remove, cards} ->
            remove_cards(cards, self())

          {:error, reason} ->
            Logger.warning("handle_cards failed for #{__MODULE__}:#{self()} '#{inspect(reason)}'")
        end

        poll(message)

        {:noreply, state}
      end

      def public_message_name(:home_dash_init), do: :init
      def public_message_name(:home_dash_poll), do: :poll
      def public_message_name(msg), do: msg

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

      def handle_cards(_message, _opts), do: {:ok, []}

      defoverridable handle_cards: 2
    end
  end

  defmacro handle_info_home_dash() do
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
end
