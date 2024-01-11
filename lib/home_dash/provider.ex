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
  @type state() :: %{
          server_pid: pid(),
          opts: opts(),
          task_supervisor_pid: pid()
        }
  @type handle_cards_response() ::
          {:ok, list(HomeDash.Card.t())}
          | {:new, list(HomeDash.Card.t())}
          | {:delete, list(HomeDash.Card.t() | String.t())}
          | {:error, term()}

  @callback subscribe(keyword(), pid(), term()) :: :ok
  @callback push_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback set_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback remove_cards(HomeDash.Card.t(), pid()) :: :ok
  @callback start_link(keyword()) :: GenServer.on_start()
  @callback handle_cards(opts()) :: handle_cards_response()

  @optional_callbacks handle_cards: 1

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
        {:ok, pid} = HomeDash.CardServer.start_link([])
        {:ok, sup_pid} = Task.Supervisor.start_link()

        state = %{server_pid: pid, opts: opts, task_supervisor_pid: sup_pid}

        {:ok, state, {:continue, :handle_cards}}
      end

      @impl true
      def handle_cast({:subscribe, pid, cid}, state) do
        HomeDash.CardServer.subscribe(pid, cid, state.server_pid)
        {:noreply, state}
      end

      def handle_cast({:push_cards, cards}, state) do
        HomeDash.CardServer.push_cards(cards, state.server_pid)
        {:noreply, state}
      end

      def handle_cast({:set_cards, cards}, state) do
        # TODO: remove old cards, only send new
        HomeDash.CardServer.push_cards(cards, state.server_pid)
        {:noreply, state}
      end

      def handle_cast({:remove_cards, cards}, state) do
        HomeDash.CardServer.delete_cards(cards, state.server_pid)
        {:noreply, state}
      end

      @impl true
      def handle_info(:poll, state) do
        {:noreply, state, {:continue, :handle_cards}}
      end

      def poll() do
        if is_integer(unquote(polling_interval)) do
            Process.send_after(self(), :poll, unquote(polling_interval))
        end
      end

      @impl true
      def handle_continue(:handle_cards, state) do
        pid = self()

        Task.Supervisor.start_child(state.task_supervisor_pid, fn ->
          case handle_cards(state.opts) do
            {:ok, cards} ->
              set_cards(cards, pid)

            {:new, cards} ->
              push_cards(cards, pid)

            {:remove, cards} ->
              remove_cards(cards, pid)

            {:error, reason} ->
              Logger.warning("handle_cards failed for #{__MODULE__}:#{pid} '#{reason}'")
          end
        end)

        poll()

        {:noreply, state}
      end

      def handle_cards(opts), do: {:ok, []}

      defoverridable handle_cards: 1
    end
  end
end
