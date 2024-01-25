defmodule HomeDash.ProviderTest do
  use ExUnit.Case, async: false

  import HomeDash.Factory

  alias HomeDash.Card

  defmodule TestProvider do
    use HomeDash.Provider

    def handle_cards(_msg, _opts) do
      cards = [build(:card, id: "1"), build(:card, id: "2"), build(:card, id: "3")]
      {:ok, cards}
    end
  end

  def id(_context) do
    {:ok, id: UUID.uuid4()}
  end

  def genserver(_context) do
    {:ok, pid} = TestProvider.start_link([])
    {:ok, pid: pid}
  end

  def subscribe(%{pid: pid, id: id}) do
    TestProvider.subscribe([], pid, id)
    assert_receive {:home_dash, :add, [%Card{}, %Card{}, %Card{}], ^id}
    :ok
  end

  describe "subscribe/3" do
    setup [:id, :genserver]

    test "sends existing cards on subscription", %{pid: pid, id: id} do
      TestProvider.subscribe([], pid, id)

      assert_receive {:home_dash, :add, [%Card{}, %Card{}, %Card{}], ^id}
    end
  end

  describe "set_cards/2" do
    setup [:id, :genserver, :subscribe]

    test "updates existing cards", %{pid: pid, id: id} do
      new_cards = [
        build(:card, id: "1", data: %{title: "Updated Card 1"}),
        build(:card, id: "2", data: %{title: "Updated Card 2"}),
        build(:card, id: "3", data: %{title: "Updated Card 3"})
      ]

      TestProvider.set_cards(new_cards, pid)

      assert_receive {:home_dash, :add, ^new_cards, ^id}
      assert_receive {:home_dash, :delete, [], ^id}
    end

    test "removes old cards", %{pid: pid, id: id} do
      TestProvider.set_cards([build(:card, id: "2")], pid)

      assert_receive {:home_dash, :add, [%Card{id: "2"}], ^id}
      assert_receive {:home_dash, :delete, [%Card{id: "1"}, %Card{id: "3"}], ^id}
    end
  end

  describe "push_cards/2" do
    setup [:id, :genserver, :subscribe]

    test "adds new cards", %{pid: pid, id: id} do
      new_cards = [
        build(:card, id: "4", data: %{title: "New Card 4"}),
        build(:card, id: "5", data: %{title: "New Card 5"})
      ]

      TestProvider.push_cards(new_cards, pid)

      assert_receive {:home_dash, :add, ^new_cards, ^id}
      assert_receive {:home_dash, :delete, [], ^id}
    end

    test "updates existing cards", %{pid: pid, id: id} do
      cards = [
        build(:card, id: "3", data: %{title: "Updated Card 3"}),
        build(:card, id: "4", data: %{title: "New Card 4"})
      ]

      TestProvider.push_cards(cards, pid)

      assert_receive {:home_dash, :add, ^cards, ^id}
      assert_receive {:home_dash, :delete, [], ^id}
    end
  end

  describe "remove_cards/2" do
    setup [:id, :genserver, :subscribe]

    test "removes cards", %{pid: pid, id: id} do
      removed_cards = [build(:card, id: "3"), build(:card, id: "4")]

      TestProvider.remove_cards(removed_cards, pid)

      assert_receive {:home_dash, :add, [], ^id}
      assert_receive {:home_dash, :delete, ^removed_cards, ^id}
    end

    test "removes cards by id", %{pid: pid, id: id} do
      TestProvider.remove_cards(["1", "2"], pid)

      assert_receive {:home_dash, :add, [], ^id}
      assert_receive {:home_dash, :delete, ["1", "2"], ^id}
    end
  end
end
