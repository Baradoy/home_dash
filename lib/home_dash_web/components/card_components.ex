defmodule HomeDashWeb.CardComponents do
  use Phoenix.Component

  attr :align, :atom, default: :right, required: false
  attr :background, :string, required: false
  attr :class, :string, default: nil
  slot(:inner_block, required: true)

  def floating_pill(assigns) do
    assigns =
      assigns
      |> assign_new(:position, fn assigns ->
        case assigns.align do
          :left -> "left-4"
          _ -> "right-4"
        end
      end)
      |> update(:background, fn
        background when is_binary(background) -> background
        nil -> "bg-blue-200 dark:bg-sky-900"
      end)

    ~H"""
    <div class={[
      "absolute top-4 py-1 px-4 rounded-full font-bold text-m capitalize",
      @background,
      @class,
      @position
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
