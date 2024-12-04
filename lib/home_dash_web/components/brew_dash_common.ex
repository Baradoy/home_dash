defmodule HomeDashWeb.BrewDashCommon do
  use Phoenix.Component

  attr :tip, :string, required: true
  slot(:inner_block, required: true)

  def tool_tip(assigns) do
    ~H"""
    <div class="relative flex flex-col items-center group">
      {render_slot(@inner_block)}
      <div class="absolute bottom-0 flex flex-col items-center hidden mb-6 group-hover:flex">
        <span class="relative z-10 p-2 text-xs leading-none text-white whitespace-no-wrap bg-gray-600 shadow-lg rounded-md">
          {@tip}
        </span>
        <div class="w-3 h-3 -mt-2 rotate-45 bg-gray-600"></div>
      </div>
    </div>
    """
  end
end
