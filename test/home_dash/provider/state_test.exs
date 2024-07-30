defmodule HomeDash.Provider.StateTest do
  use ExUnit.Case, async: true

  import HomeDash.Factory

  alias HomeDash.Provider.State

  def state(_context) do
    {:ok, state: State.new([])}
  end

  def pids(_context) do
    {:ok, pid: spawn(fn -> 1 end), other_pid: spawn(fn -> 1 end)}
  end

  describe "add_cards/2" do
    setup [:state]

    test "handles empty cards", %{state: state} do
      new_cards = []

      assert {^state, [], []} = State.add_cards(state, new_cards)
    end

    test "adds cards to an empty list", %{state: state} do
      new_cards = [build(:card, id: "1"), build(:card, id: "2")]

      assert {new_state, ^new_cards, []} = State.add_cards(state, new_cards)

      assert assert_cards(new_state, new_cards)
    end

    test "adds cards to existing cards", %{state: state} do
      initial_cards = [build(:card, id: "1"), build(:card, id: "2")]
      state = with_cards(state, initial_cards)

      new_cards = [build(:card, id: "3"), build(:card, id: "4")]

      assert {new_state, ^new_cards, []} = State.add_cards(state, new_cards)

      assert assert_cards(new_state, initial_cards ++ new_cards)
    end

    test "adds cards to overlapping existing cards", %{state: state} do
      initial_cards = [build(:card, id: "1"), build(:card, id: "2")]
      state = with_cards(state, initial_cards)

      new_cards = [build(:card, id: "2"), build(:card, id: "3")]

      assert {new_state, ^new_cards, []} = State.add_cards(state, new_cards)

      assert assert_cards(new_state, initial_cards ++ new_cards)
    end

    test "prefers new cards to old cards", %{state: state} do
      initial_cards = [build(:card, id: "1", data: %{title: "Old Data"})]
      state = with_cards(state, initial_cards)

      new_cards = [build(:card, id: "1", data: %{title: "New Data"}), build(:card, id: "2")]

      assert {new_state, ^new_cards, []} = State.add_cards(state, new_cards)

      assert assert_cards(new_state, new_cards)
    end
  end

  describe "set_cards/2" do
    setup [:state]

    test "sets empty cards", %{state: state} do
      cards = []

      assert {new_state, [], []} = State.set_cards(state, cards)

      assert assert_cards(new_state, [])
    end

    test "sets empty cards overides existing cards", %{state: state} do
      initial_cards = [build(:card, id: "1"), build(:card, id: "2")]
      state = with_cards(state, initial_cards)

      cards = []

      assert {new_state, [], ^initial_cards} = State.set_cards(state, cards)

      assert assert_cards(new_state, [])
    end

    test "sets new cards over empty cards", %{state: state} do
      initial_cards = [build(:card, id: "1"), build(:card, id: "2")]
      state = with_cards(state, initial_cards)

      cards = [build(:card, id: "1"), build(:card, id: "2")]

      assert {new_state, ^cards, []} = State.set_cards(state, cards)

      assert assert_cards(new_state, cards)
    end

    test "sets new cards over existing cards", %{state: state} do
      initial_cards = [build(:card, id: "1"), build(:card, id: "2")]
      state = with_cards(state, initial_cards)

      cards = [build(:card, id: "3"), build(:card, id: "4")]

      assert {new_state, ^cards, ^initial_cards} = State.set_cards(state, cards)

      assert assert_cards(new_state, cards)
    end

    test "overrides exisitng cards, prefers exisitng cards", %{state: state} do
      initial_cards =
        [_, removed] = [build(:card, id: "1", data: %{title: "Old Data"}), build(:card, id: "2")]

      state = with_cards(state, initial_cards)

      cards = [build(:card, id: "1", data: %{title: "Old Data"}), build(:card, id: "3")]

      assert {new_state, ^cards, [^removed]} = State.set_cards(state, cards)

      assert assert_cards(new_state, cards)
    end
  end

  describe "remove_cards/2" do
    setup [:state]

    test "handles empty lists", %{state: state} do
      cards = []

      assert {^state, [], []} = State.remove_cards(state, cards)
    end

    test "removes existing cards ", %{state: state} do
      initial_cards =
        [first, second, third] = [
          build(:card, id: "1"),
          build(:card, id: "2"),
          build(:card, id: "3")
        ]

      state = with_cards(state, initial_cards)

      cards = [first, third]

      assert {new_state, [], ^cards} = State.remove_cards(state, cards)

      assert assert_cards(new_state, second)
    end

    test "egnores non-existing cards ", %{state: state} do
      initial_cards =
        [first, second] = [build(:card, id: "1"), build(:card, id: "2")]

      state = with_cards(state, initial_cards)

      cards = [first, build(:card, id: "3")]

      assert {new_state, [], ^cards} = State.remove_cards(state, cards)

      assert assert_cards(new_state, second)
    end
  end

  describe "add_subscription/3" do
    setup [:state, :pids]

    test "adds a subscription", %{state: state, pid: pid} do
      new_state = State.add_subscription(state, pid, "component_id")

      assert new_state.subscriptions == [{pid, "component_id"}]
    end

    test "adds duplicate subscription pids", %{state: state, pid: pid} do
      new_state =
        state
        |> State.add_subscription(pid, "component_id")
        |> State.add_subscription(pid, "other_id")

      assert new_state.subscriptions == [{pid, "other_id"}, {pid, "component_id"}]
    end
  end

  describe "remove_subscription/2" do
    setup [:state, :pids]

    test "removes a subscription", %{state: state, pid: pid} do
      new_state =
        state
        |> State.add_subscription(pid, "component_id")
        |> State.remove_subscription(pid)

      assert new_state.subscriptions == []
    end

    test "removes duplicate subscription pids", %{state: state, pid: pid} do
      new_state =
        state
        |> State.add_subscription(pid, "component_id")
        |> State.add_subscription(pid, "other_id")
        |> State.remove_subscription(pid)

      assert new_state.subscriptions == []
    end

    test "ignores non-existent pids", %{state: state, pid: pid, other_pid: other_pid} do
      new_state =
        state
        |> State.add_subscription(pid, "component_id")
        |> State.remove_subscription(other_pid)

      assert new_state.subscriptions == [{pid, "component_id"}]
    end
  end

  defp assert_cards(state, cards) do
    state_keys = Map.keys(state.cards)

    keys =
      cards
      |> List.wrap()
      |> Enum.map(fn
        card ->
          assert card.id in state_keys
          assert state.cards[card.id] == card
          card
      end)
      |> Enum.map(fn card ->
        card.id
      end)

    remaining_cards = Map.drop(state.cards, keys)
    assert Map.equal?(remaining_cards, %{})
  end
end
