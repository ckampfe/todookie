defmodule TodookieWeb.Modal do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :show, :boolean, default: false

  slot :inner_block
  slot :title
  slot :actions

  def modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-window-keydown="close-modal"
      phx-key="escape"
    >
      <!-- backdrop -->
      <div
        class="absolute inset-0 bg-black/50"
        phx-click="close-modal"
      />
      
    <!-- dialog -->
      <div class="relative z-10 w-full max-w-md rounded bg-white p-6 shadow-xl">
        <div class="mb-4 text-lg font-bold">
          {render_slot(@title)}
        </div>

        <div class="mb-6">
          {render_slot(@inner_block)}
        </div>

        <div class="flex justify-left gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end
end
