defmodule HomeDashWeb.CardComponents do
  use Phoenix.Component

  attr :align, :atom, default: :right, required: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def floating_pill(assigns) do
    assigns =
      assign_new(assigns, :position, fn assigns ->
        case assigns.align do
          :left -> "left-4"
          _ -> "right-4"
        end
      end)

    ~H"""
    <div class={[
      "absolute top-4 py-1 px-4 rounded-full font-bold text-m capitalize",
      "[:where(&)]:bg-blue-200 [:where(&)]:dark:bg-sky-900",
      @class,
      @position
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
