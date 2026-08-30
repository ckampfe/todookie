defmodule TodookieWeb.ListComponent do
  use TodookieWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id={"column-id-#{@column.id}"}
      data-column_id={@column.id}
      phx-hook="DoubleClick"
      class="bg-gray-100 py-4 rounded-lg overflow-y-auto flex flex-col min-h-0"
    >
      <div class="space-y-5 mx-auto w-full max-w-7xl px-4 space-y-4 flex flex-col flex-1">
        <header id={"#{@column.name}-title"}>
          <div class="flex">
            {@column.name}
          </div>
        </header>
        <div
          id={"#{@id}-items"}
          phx-hook="Sortable"
          data-column_id={@column.id}
          data-group={@group}
          class="flex-1 min-h-12"
        >
          <div
            :for={card <- @column.cards}
            id={"card-#{card.id}"}
            class="
            drag-item:focus-within:ring-0
            drag-item:focus-within:ring-offset-0

            pb-2
            "
            data-card_id={card.id}
            phx-hook="DoubleClick"
          >
            <div class="
              drag-ghost:bg-zinc-300
              drag-ghost:border-1
              drag-ghost:ring-0

              rounded-lg
              bg-gray-50
              py-2
              border-1
              border-solid
              border-zinc-500
              ">
              <div class="flex drag-ghost:opacity-0">
                <div class="flex-auto mx-2 block text-sm leading-6 text-zinc-900">
                  {card.title}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("reposition", params, socket) do
    send(self(), {:reposition, params})
    {:noreply, socket}
  end

  def handle_event("double-click", params, socket) do
    send(self(), {:double_click, params})
    {:noreply, socket}
  end
end
